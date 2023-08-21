# SimpleSiteSelector
The "SimpleSiteSelector" is a script to provide a user choosen or enforced site assignment via jamf pro (or other mdm). GUI is based on swiftDialog.
The "SimpleSiteSelector" could be run directly after enrollment or within enrollment.

I will publish the SimpleEnrollmentScript with the site selectore feature too soon, to provide site assignment during prestage enrollment.

Why i created the script?

Within a customer enviroment all devices should be enrolled into a default site like "staged". This should be done during the prestage enrollment. After the device is succcesful enrolled to that site, the device should be assigned to a site based on LDAP Attribute.

LDAP Attribute assignement coult be archived by smart groups, but how to move the device to the site? Well we have the Jamf API.

Witht he provided informations the Script assign the device to the desired site in the tenant.

---

# The script will be configured by the script paramters:

- Parameter 4: Available site IDs for bulk (single id) or usermode (comma seperated)
- Parameter 5: mode "usermode" or "bulk"
- Parameter 6: Jamf api username (see user permission requirements)
- Parameter 7: Jamf api password
- Parameter 8: sript titel
- Parameter 9: main message
- Parameter 10: icon

# Parameter details:
# Parameter 4
- usermode: comma seperated site ids
- bulk: single site id

# Parameter 5
- usermode: shows the user a swiftDialog based GUI to select the desired site
- bulk: assigne the specified site to all devices in the scope

# Parameter 6
- API username
- requires the following API rights

# Parameter 7
- secure password
- lenght 20, contains a-z,A-Z,1-9.Symbols

# Parameter 8
- script titel shown for the GUI
  
# Parameter 9
- message shown for the GUI

# Parameter 10
- icon shown for the GUI
