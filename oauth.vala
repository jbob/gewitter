/*
Copyright (C) 2011 by Alexander Wood

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

/**
 * oAuth 1.0 Spec: http://tools.ietf.org/html/rfc5849
 * Flow Diagram: http://si0.twimg.com/images/dev/oauth_diagram.png
 */

using Soup;
using Gee;

namespace OAuth
{
  public const string VERSION = "1.0";
  
  public errordomain Error {
    INVALID_ARGUMENT
  }
  
  public class Client : Object
  {
    private ISignatureMethod oauth_signature_method;
    private string oauth_consumer_key;
    
    private string oauth_token;
    private string oauth_token_secret;
    
    private string realm;
    
    public Client(string realm, string oauth_consumer_key, ISignatureMethod sigmeth)
    {
      this.realm = realm;
      this.oauth_consumer_key = oauth_consumer_key;
      this.oauth_signature_method = sigmeth;
    }
  
    // RFC 5849 Section 2.1.
    // (Diagram: "[A] Consumer Requests Request Token")
    // Remember, a HTTP "POST" request is recommended.
    public Map<string, string> request_token(string http_method, string request_endpoint_uri, string oauth_callback = "oob")
    {
      oauth_token = oauth_token_secret = null;
       
      HashMultiMap<string, string> args = new HashMultiMap<string, string>();
      //Do not include the "realm" parameter. (Section 3.4.1.3.1.)
      args.set("oauth_consumer_key", oauth_consumer_key);
      args.set("oauth_signature_method", oauth_signature_method.to_string());
      args.set("oauth_timestamp", get_timestamp());
      args.set("oauth_nonce", get_nonce());
      args.set("oauth_version", VERSION);
      args.set("oauth_callback", oauth_callback);
      
      return process(http_method, request_endpoint_uri, args);
    }
    
    // RFC 5849 Section 2.2.
    // Begin to exchange the request token we just got for an access token.
    // The user needs to visit the returned uri and authorize this request.
    // (Diagram: "[B] Service Provider Grants Request Token", "[C] Consumer Directs User to Service Provider")
    public string auth_token(string auth_endpoint_uri_template, string oauth_token, string oauth_token_secret, string oauth_callback_confirmed) throws OAuth.Error 
    {
      if (oauth_callback_confirmed != "true") throw new OAuth.Error.INVALID_ARGUMENT("oauth_callback_confirmed");
      this.oauth_token = oauth_token;
      this.oauth_token_secret = oauth_token_secret;
      return auth_endpoint_uri_template.printf(oauth_token);
    }
    
    public string get_oauth_token() { return oauth_token; }
    
    // RFC 5849 Section 2.3.
    // (Diagram: "[D] Service Provider Directs User to Consumer", "[E] Consumer Requests Access Token")
    // Remember, a HTTP "POST" request is recommended.
    public Map<string, string> access_token(string http_method, string access_endpoint_uri, string oauth_token, string oauth_verifier) throws OAuth.Error
    {
      if (oauth_token != this.oauth_token) throw new OAuth.Error.INVALID_ARGUMENT("oauth_token");
       
      MultiMap<string, string> args = new HashMultiMap<string, string>();
      args.set("oauth_verifier", oauth_verifier);
      
      return authenticate(http_method, access_endpoint_uri, args);
    }
    
    // (Diagram: "[F] Service Provider Grants Access Token")
    // Also callable at normal startup when we already have our access token.
    public void set_token(string oauth_token, string oauth_token_secret)
    {
      this.oauth_token = oauth_token;
      this.oauth_token_secret = oauth_token_secret;
    }
    
    // RFC 5849 Section 3.1.
    // Normal, everyday requests.
    // (Diagram: "[G] Consumer Accesses Protected Resources")
    public Map<string, string> authenticate(string http_method, string uri, MultiMap<string, string>? args_ = null)
    {
      MultiMap<string, string> args = args_ ?? new HashMultiMap<string, string>();
      
      //Do not include the "realm" parameter. (Section 3.4.1.3.1.)
      args.set("oauth_consumer_key", oauth_consumer_key);
      args.set("oauth_token", oauth_token);
      args.set("oauth_signature_method", oauth_signature_method.to_string());
      args.set("oauth_timestamp", get_timestamp());
      args.set("oauth_nonce", get_nonce());
      args.set("oauth_version", VERSION);
      
      return process(http_method, uri, args);
    }
    
    // RFC 5849 Section 3.5.1.
    private Map<string, string> process(string http_method, string uri, MultiMap<string, string> parameters)
    {
      string signature_base = signature_base_string(http_method, uri, parameters);
      string signature = oauth_signature_method.sign(oauth_token_secret, signature_base);
      string auth_header = "OAuth realm=\"" + realm + "\",";
      string auth_query = "";
      string query = "";
      string amperstand = "";
      foreach (var key in parameters.get_keys())
      {
        if (key.has_prefix("oauth_"))
        {
          string enckey = percent_encode(key);
          if (parameters.get(key).size == 0) { //Blanks must be represented.
            auth_header += enckey + "=\"\",";
            auth_query += enckey + "=&";
          } else {
            foreach (var val in parameters.get(key)) {
              auth_header += enckey + "=\"" + percent_encode(val) + "\",";
              auth_query += enckey + "=" + percent_encode(val) + "&";
            }
          }
        }
        else 
        {
          string enckey = URI.encode(key, null);
          if (parameters.get(key).size == 0)
            query += amperstand + enckey + "=";
          else
            query += amperstand + str_join(parameters.get(key), "&", (val) => { return enckey+"="+URI.encode(val, null); });
          amperstand = "&";
        }
      }
      auth_header += "oauth_signature=\"" + percent_encode(signature) + "\"";
      auth_query += "oauth_signature=" + percent_encode(signature);
      
      HashMap<string, string> ret = new HashMap<string, string>();
      ret.set("query", query);
      ret.set("Authorization", auth_header);
      ret.set("authquery", auth_query);
      ret.set("Host", uri_hostname(uri));
      return ret;
    }
  }
  
  // RFC 5849 Section 3.3.
  // The timestamp value MUST be a positive integer.  Unless otherwise
  // specified by the server's documentation, the timestamp is expressed
  // in the number of seconds since January 1, 1970 00:00:00 GMT.
  private string get_timestamp()
  {
    return ((long)time_t()).to_string();
  }
  // A nonce is a random string, uniquely generated by the client to allow
  // the server to verify that a request has never been made before and
  // helps prevent replay attacks when requests are made over a non-secure
  // channel.  The nonce value MUST be unique across all requests with the
  // same timestamp, client credentials, and token combinations.
  private string get_nonce()
  {
    return Random.next_int().to_string();
  }
  
  // RFC 5849 Section 3.4.
  // This library implements PLAINTEXT and HMAC-SHA1.
  public interface ISignatureMethod : Object
  {
    public abstract string sign(string? token_secret, string sig_base);
    public abstract string to_string();
  }
  
  public class PLAINTEXT : Object, ISignatureMethod
  {
    public PLAINTEXT(string secret) { this.oauth_consumer_secret = secret; }
    
    string oauth_consumer_secret;
    
    public string sign(string? token_secret, string sig_base) 
    {
      return percent_encode(oauth_consumer_secret) + "&" + percent_encode(token_secret ?? "");
    }
    public string to_string() { return "PLAINTEXT"; }
  }
  
  public class HMAC_SHA1 : Object, ISignatureMethod
  {
    public HMAC_SHA1(string secret) { this.oauth_consumer_secret = secret; }  
  
    string oauth_consumer_secret;

    public string sign(string? token_secret, string sig_base)
    {
      string secrets = percent_encode(oauth_consumer_secret) + "&" + percent_encode(token_secret ?? "");
      return Base64.encode(HMAC.hmac_sha1((uchar[])secrets.to_utf8(), (uchar[])sig_base.to_utf8()));
    }
    public string to_string() { return "HMAC-SHA1"; }
  }
 
  // RFC 5849 Section 3.4.1.1.
  private string signature_base_string(string http_method, string uri, MultiMap<string, string> parameters)
  {
    string ret;
  
    //1. The HTTP request method in uppercase. (If custom, must be encoded (Section 3.6).)
    ret = percent_encode(http_method.up());
    
    //2. An "&" character (ASCII code 38).
    ret += "&";
    
    //3. The base string URI from Section 3.4.1.2, after being encoded (Section 3.6).
    //Section 3.4.1: The authority as declared by the HTTP "Host" request header field.
    ret += percent_encode(signature_base_string_uri(uri));
    
    //4. An "&" character (ASCII code 38).
    ret += "&";
    
    //5. The request parameters as normalized in Section 3.4.1.3.2, after being encoded (Section 3.6).
    //Section 3.4.1: The protocol parameters excluding the "oauth_signature".
    parameters.remove_all("oauth_signature"); //Sanity.
    ret += percent_encode(parameters_normalization(parameters));
    
    return ret;
  }
  
  // RFC 5849 Section 3.4.1.2.
  private string signature_base_string_uri(string uri)
  {
    URI ret = new URI(uri);
    ret.set_scheme(ret.scheme.down());
    ret.set_host(uri_hostname(uri));
    ret.query = ret.fragment = null;
    return ret.to_string(/*just_path_and_query=*/false);
  }
  private string uri_hostname(string uri)
  {
    URI ret = new URI(uri);
    return ret.host.down();
  }
  
  // RFC 5849 Section 3.4.1.3.2.
  private string parameters_normalization(MultiMap<string, string> parameters)
  {
    //1. First, the name and value of each parameter are encoded (Section 3.6).
    HashMap<string, ArrayList<string>> encodedp = new HashMap<string, ArrayList<string>>();
    ArrayList<string> keys = new ArrayList<string>();
    foreach (var key in parameters.get_keys())
    {
      string enckey = percent_encode(key);
      keys.add(enckey);
      encodedp[enckey] = new ArrayList<string>();
      foreach (var val in parameters.get(key))
        encodedp[enckey].add(percent_encode(val));
    }
    
    //2. The parameters are sorted by name, using ascending byte value ordering.
    //   If two or more parameters share the same name, they
    //   are sorted by their value.
    keys.sort((CompareFunc)strcmp);
    
    //3. The name of each parameter is concatenated to its corresponding
    //   value using an "=" character (ASCII code 61) as separator, even
    //   if the value is empty.
    //4. The sorted name/value pairs are concatenated together into a
    //   single string by using an "&" character (ASCII code 38) as
    //   separator.
    return str_join(keys, "&", (key) => {
      var values = encodedp.get(key);
      if (values.size == 0) return key+"=";
      values.sort((CompareFunc) strcmp);
      return str_join(values, "&", (val) => {
        return key+"="+val;
      });
    });
  }
  
  // RFC 5849 Section 3.6.
  // The RFC is very very specific on what to do;
  // it is important that this matches the spec
  // because signature_base_string uses this.
  // If URI.encode was used, the extras parameter begins to look ugly and bulky _fast_.
  private string percent_encode(string payload)
  {
    string ret = "";
  
    //1. Text values are first encoded as UTF-8 octets per [RFC3629] if they are not already.
    char[] chars = payload.to_utf8();
    
    //2. The values are then escaped using the [RFC3986] percent-encoding (%XX) mechanism as follows:
    foreach (char c in chars)
    {
      if (c.isalpha() || c.isdigit() || c == '-' || c == '.' || c == '_' || c == '~')
        ret += c.to_string();
      else
        ret += "%%%02X".printf((uchar)c & 0xFF);
    }
    
    return ret;
  }
  
  //Utility function
  private delegate string StringOperation(string input);
  private string str_join(Iterable<string> collection, string separator, StringOperation f)
  {
    string ret = null;
    foreach (string str in collection)
    {
      if (ret == null) ret = f(str);
      else ret += separator + f(str);
    }
    return ret;
  }
}

// Warning: This is a quick-and-dirty HMAC-SHA1 implementation. But it works.

namespace HMAC {
  private uchar[] sha1(uchar[] data1, uchar[]? data2=null)
  {
    uchar[] ret = new uchar[20]; size_t ret_len = 20;
    var cksm = new Checksum(ChecksumType.SHA1);
    cksm.update(data1, data1.length);
    if (data2 != null) cksm.update(data2, data2.length);
    cksm.get_digest((uint8[])ret, ref ret_len);
    assert(ret_len == 20);
    return ret;
  }
  private uchar[] hmac_sha1(uchar[] _key, uchar[] message)
  {
    const int blocksize = 64;

    uchar[] key = _key;
    if (key.length > blocksize) key = sha1(key);
    while (key.length < blocksize) key += 0;
    
    uchar okey[64]; uchar ikey[64]; //<--blocksize (magic numbers because Vala doesn't accept a const int here)
    for (size_t i=0;i<blocksize;i++)
    {
      okey[i] = 0x5c ^ key[i];
      ikey[i] = 0x36 ^ key[i];
    }
    
    return sha1(okey, sha1(ikey, message));
  }
}

