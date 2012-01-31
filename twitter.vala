using Gee;
using Soup;
using Json;

public class Twitter {

	private OauthTwitter ot;

	public Twitter() {
		ot = new OauthTwitter();
	}

	public void init(string token, string token_secret) {
		ot.init(token, token_secret);
	}

	public void getAccessToken_A() {
		ot.getAccessToken_A();
	}

	public Map<string, string> getAccessToken_B(string pin) {
		return ot.getAccessToken_B(pin);
	}

	public Json.Parser home_timeline(MultiMap<string, string> parameters) {
		Soup.Session session = new Soup.SessionAsync();
		Soup.Message message = ot.Auth("GET",
				"https://api.twitter.com/1/statuses/home_timeline.json", parameters);
		session.send_message(message);
		var parser = new Json.Parser();
		try {
			parser.load_from_data((string)message.response_body.flatten().data, -1);
		} catch(GLib.Error e) {
			print("Error: "+e.message);
		}

		return parser;
	}
}
