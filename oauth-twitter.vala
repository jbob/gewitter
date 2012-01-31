using OAuth;
using Soup;
using Gee;

public class OauthTwitter {
	private const string realm = "";
	private const string key = "BiU5K4R91bPpwqMKThbC1w";
	private const string secret = "eFjBWU8dbtkyLnEKLnARAoLmHkmtZsPfWLAdzrRY6R0";
	private OAuth.Client client;
	private string token = "";

	public OauthTwitter() { 
		client = new OAuth.Client(realm, key, new OAuth.HMAC_SHA1(secret));
	}

	public void init(string token, string token_secret) {
		client.set_token(token, token_secret);
	}

	public void getAccessToken_A() {
		const string method = "POST";
		const string url_request = "http://api.twitter.com/oauth/request_token";
		const string callback = "oob";
		const string url_authorize =
										"https://api.twitter.com/oauth/authorize?oauth_token=%s";

		Map<string, string> request;
		request = client.request_token(method, url_request, callback);
		string request_auth = request["Authorization"];

		// TODO: Why the fuck is Async not working?
		var session = new Soup.SessionSync();
		var message = new Soup.Message(method, url_request);
		message.request_headers.append("Authorization", request_auth);

		session.send_message(message);
		string[] parts = ((string)message.response_body.flatten().data).split("&");
		string token_secret = "";
		foreach(string part in parts) {
			string[] p = part.split("=");
			if(p[0] == "oauth_token") {
				token = p[1];
			} else if(p[0] == "oauth_token_secret") {
				token_secret = p[1];
			}
		}

		string url = "";
		try {
			url = client.auth_token(url_authorize, token, token_secret, "true");
		} catch(OAuth.Error e) {
			print("Error: "+e.message);
		}

		try {
			print(url+"\n");
			Process.spawn_command_line_async("xdg-open '"+url+"'");
		} catch(SpawnError e) {
			print("Error: "+e.message);
		}
	}
		
	public Map<string, string> getAccessToken_B(string pin) {
		const string method = "POST";
		const string url_access = "https://api.twitter.com/oauth/access_token";

		Map<string, string> access = new HashMap<string, string>();
		try {
			access = client.access_token(method, url_access, token, pin);
		} catch(OAuth.Error e) {
			print("Error: "+e.message);
		}
		string access_auth = access["Authorization"];

		// TODO: Why the fuck is Async not working?
		var session = new Soup.SessionSync();
		var message = new Soup.Message(method, url_access);
		message.request_headers.append("Authorization", access_auth);

		session.send_message(message);
		string[] parts = ((string)message.response_body.data).split("&");
		string token = "";
		string token_secret = "";
		foreach(string part in parts) {
			string[] p = part.split("=");
			if(p[0] == "oauth_token") {
				token = p[1];
			} else if(p[0] == "oauth_token_secret") {
				token_secret = p[1];
			}
		}
		client.set_token(token, token_secret);
		var ret = new HashMap<string, string>();
		ret.set("consumer_key", token);
		ret.set("consumer_secret", token_secret);
		return ret;
	}

	public Soup.Message Auth(string method,
													 string url,
													 MultiMap<string, string>? parameters = null) {
		string myurl = url;
		if(parameters != null ) {
			myurl += "?";
			foreach(var key in parameters.get_keys()) {
				foreach(var value in parameters.get(key)) {
					myurl += key + "=" + value + "&";
				}
			}
			myurl = myurl[0:myurl.length-1];
		}
		print(myurl+"\n");
		var message = new Soup.Message(method, myurl);
		var oauth_header = client.authenticate(method, url, parameters)["Authorization"];
		message.request_headers.append("Authorization", oauth_header);
		return message;
	}
}

