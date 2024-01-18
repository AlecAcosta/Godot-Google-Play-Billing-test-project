# Godot Google Play Billing test project
A test project with a ready to use gd script to implement google play billing easily in your own project

The objective of this repository is to have an easier way to interact with the Godot Google Play Billing plugin
I'm not an expert but I have working games on the Google Play Store using this plugin and script

Currently tested using Google Play Billing **1.2.0**

First add the android build template to your project:
 -From the Godot editor just go to Project->Install Android Build Template

Then you need to download the plugin from https://github.com/godotengine/godot-google-play-billing/releases
Put the .gdap and .aar files in android/plugins, check the release version

Download and add the GooglePB.gd and GooglePB.tscn files of this repository to your project

Add GooglePB.tscn to the autoload list:
 -From the Godot editor go to Project->ProjectSettings->Autoloads And add GooglePB.tscn, leave the name as GooglePB, this is the autoload name and it's case sensitive

Add the product id's
 -Open GooglePB.tscn in godot and in the Inspector->ScriptVariables add the product id's
 -add them to the "Persistent" list if it's meant to stay in the account of the User, like premium mode
 -add them to the "Non Persistent" list if it's meant to be purchased multiple times, like coin bags

To purchase just call the autoload **GooglePB.payment.purchase("your product id")**
Add a Node to a group called **"gpb listener"** so it can listen the Plugin when a purchase is made

In your node added to the "gpb listener" group make a function called **_on_purchase_successful(_product_id)**
This function gets called automatically when a purchase is successfully made, there you can grant the purchased product using it's id
