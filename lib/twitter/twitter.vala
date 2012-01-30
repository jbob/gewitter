using Soup;
using Json;
using OAuth;

namespace twitter {
	public Json.Parser home_timeline(OauthTwitter ot) {
		Soup.Session session = new Soup.SessionAsync();
		Soup.Message message = ot.Auth("GET",
										"https://api.twitter.com/1/statuses/home_timeline.json");
		session.send_message(message);
		var parser = new Json.Parser();
		parser.load_from_data((string)message.response_body.flatten().data, -1);

		return parser;
	}
}
