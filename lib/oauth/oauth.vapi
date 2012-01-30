/* oauth.vapi generated by valac 0.14.0, do not modify. */

namespace OAuth {
	[CCode (cheader_filename = "oauth.h")]
	public class Client : GLib.Object {
		public Client (string realm, string oauth_consumer_key, OAuth.ISignatureMethod sigmeth);
		public Gee.Map<string,string> access_token (string http_method, string access_endpoint_uri, string oauth_token, string oauth_verifier) throws OAuth.Error;
		public string auth_token (string auth_endpoint_uri_template, string oauth_token, string oauth_token_secret, string oauth_callback_confirmed) throws OAuth.Error;
		public Gee.Map<string,string> authenticate (string http_method, string uri, Gee.MultiMap<string,string>? args_ = null);
		public string get_oauth_token ();
		public Gee.Map<string,string> request_token (string http_method, string request_endpoint_uri, string oauth_callback = "oob");
		public void set_token (string oauth_token, string oauth_token_secret);
	}
	[CCode (cheader_filename = "oauth.h")]
	public class HMAC_SHA1 : GLib.Object, OAuth.ISignatureMethod {
		public HMAC_SHA1 (string secret);
	}
	[CCode (cheader_filename = "oauth.h")]
	public class PLAINTEXT : GLib.Object, OAuth.ISignatureMethod {
		public PLAINTEXT (string secret);
	}
	[CCode (cheader_filename = "oauth.h")]
	public interface ISignatureMethod : GLib.Object {
		public abstract string sign (string? token_secret, string sig_base);
		public abstract string to_string ();
	}
	[CCode (cheader_filename = "oauth.h")]
	public errordomain Error {
		INVALID_ARGUMENT
	}
	[CCode (cheader_filename = "oauth.h")]
	public const string VERSION;
	[CCode (cheader_filename = "oauth.h")]
	public static void sanity_check ();
}
namespace HMAC {
}
