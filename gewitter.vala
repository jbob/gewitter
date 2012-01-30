using Gtk;
using Gee;
using Json;

public class Gewitter {
	private Gtk.Builder builder;
	private Gtk.Window window;
	private Gtk.Dialog dialog;
	private Gtk.Button PinCancel;
	private Gtk.Button PinOK;
	private Gtk.Entry PinEntry;
	private Gtk.ToolButton Home;
	private Gtk.ScrolledWindow Scrolled;
	private Gtk.TreeView View;
	private Gtk.ListStore List;
	private string ConfigFile = GLib.Environment.get_user_config_dir()+"/gewitterrc";
	private Map<string, string> config;
	private Twitter twitter = new Twitter();
	//private OauthTwitter ot = new OauthTwitter();


	public Gewitter() {
		builder = new Gtk.Builder();
		try {
			builder.add_from_file("gewitter.ui");
		} catch(GLib.Error e) {
			error("Unable to load UI file: " + e.message);
		}
		window = builder.get_object("window1") as Gtk.Window;
		dialog = builder.get_object("dialog1") as Gtk.Dialog;
		PinCancel = builder.get_object("button2") as Gtk.Button;
		PinOK = builder.get_object("button3") as Gtk.Button;
		PinEntry = builder.get_object("entry1") as Gtk.Entry;
		Home = builder.get_object("toolbutton1") as Gtk.ToolButton;
		Scrolled = builder.get_object("scrolledwindow1") as Gtk.ScrolledWindow;
		View = builder.get_object("treeview1") as Gtk.TreeView;
		List = builder.get_object("liststore1") as Gtk.ListStore;
		
		View.insert_column_with_attributes(-1, "User", new CellRendererText(), "text", 0);
		View.insert_column_with_attributes(-1, "Text", new CellRendererText(), "text", 1);


		window.destroy.connect(Gtk.main_quit);
		window.key_press_event.connect(KeyPressed);
		PinCancel.clicked.connect(Gtk.main_quit);
		PinOK.clicked.connect(PinOKClicked);
		Home.clicked.connect(HomeClicked);

		config = parseConfig(ConfigFile);
	}

	public void run(string[] args) {
		if(!(config.has_key("consumer_key") &&
				 config.has_key("consumer_secret"))) {
			twitter.getAccessToken_A();
		  dialog.show();
		} else {
			twitter.init(config["consumer_key"], config["consumer_secret"]);
		}
		window.show_all();
		Gtk.main();
	}

	private Map<string, string> parseConfig(string file) {
		// TODO: Implement
		var config = new HashMap<string, string>();
		string content;
		try {
			FileUtils.get_contents(file, out content);
		} catch(FileError e) {
			print("No config file, first start?\n");
			return config;
		}
		string[] contentline = content.split("\n");
		foreach(string line in contentline) {
			if(!(line.contains("=")) || line[0] == '#') {
				continue;
			}
			string[] pline = line.split("=");
			config.set(pline[0], pline[1]);
		}
		return config;
	}

	private void writeConfig(string file) {
		string configstring = "";
		foreach(var foo in config.entries) {
			string configline = foo.key+"="+foo.value+"\n";
			configstring += configline;
		}
		try {
			FileUtils.set_contents(file, configstring);
		} catch(FileError e){
			print("Error: "+e.message);
		}
	}

	private bool KeyPressed(Widget source, Gdk.EventKey key) {
		if(key.str == "j") {
			double cur = Scrolled.get_vadjustment().get_value();
			cur += 10;
			Scrolled.get_vadjustment().set_value(cur);
		}
		if(key.str == "k") {
			double cur = Scrolled.get_vadjustment().get_value();
			cur -= 10;
			Scrolled.get_vadjustment().set_value(cur);
		}
		return true;
	}

	private void PinOKClicked() {
		// TODO: Implement
		dialog.hide();
		string pin = PinEntry.get_text();
		Map<string, string> tokens = twitter.getAccessToken_B(pin);
		foreach(var token in tokens.entries) {
			config.set(token.key, token.value);
		}
		writeConfig(ConfigFile);
	}

	private void HomeClicked() {
		var json_response = twitter.home_timeline();
		var root_node = json_response.get_root();
		Gtk.TreeIter iter;
		foreach(var tweetnode in root_node.get_array().get_elements()) {
			var tweetobject = tweetnode.get_object();
			var user = tweetobject.get_object_member("user").get_string_member("name");
			var text = tweetobject.get_string_member("text");
			List.append(out iter);
			List.set_value(iter, 0, user);
			List.set_value(iter, 1, text);
		}
	}


	public static int main(string[] args) {
		Gtk.init(ref args);
		var app = new Gtk.Application("org.gnome.gewitter", 0);
		app.activate.connect(() => {
			weak GLib.List list = app.get_windows();
			if(list == null) {
				var mainwindow = new Gewitter();
				mainwindow.run(args);
			} else {
				debug("already running!");
			}
		});
		return app.run(args);
	}
}
