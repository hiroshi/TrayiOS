Tray iOS
========


Setup
-----

Create your Secrets.h

    #ifndef TrayiOS_Secrets_h
    #define TrayiOS_Secrets_h
    
    #define DROPBOX_APP_KEY @"<Your Dropbox App Key>"
    #define DROPBOX_APP_SECRET @"<Your Dropbox App Secret"
    #define ZEROPUSH_APP_TOKEN @"<Your Zeropush App Token>"

    #endif

Replace the URL scheme with "db-<Your Dropbox App Key>"

else you will get error like following:

    [ERROR] DropboxSDK: unable to link; app isn't registered for correct URL scheme (db-sues46e60vtc5p5)
