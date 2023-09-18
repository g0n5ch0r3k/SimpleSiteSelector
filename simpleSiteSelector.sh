#!/bin/bash

###########################################################################
#
# Enviroment
simpleSiteSelectorVersion="1.1"
jamfPlist="/Library/Preferences/com.jamfsoftware.jamf.plist"
jamfUrl=$(defaults read "$jamfPlist" jss_url)
#
randomString=$(printf "%08d\n" $((RANDOM % 100000000)))
dialogcmd="/Library/Application Support/Dialog/Dialog.app"
commandFile="/var/tmp/site_selector_$randomString.log"


###########################################################################
#
# Variables
	four="${4:-"1"}" # Available site IDs for usermode (single id) or bulk (comma seperated)
	five="${5:-"bulk"}" # mode usermode or bulk
	six="${6:-"apiuser"}" # Jamf api username (see user permission requirements)
	seven="${7:-"apiuser"}" # Jamf api password
	eight="${8:-"Simple Site Selector v.$simpleSiteSelectorVersion"}" # sript titel
	nine="${9:-"Please select the site to start enrollment"}" # main message
	ten="${10:-"SF=arrow.down.circle.fill,colour1=teal,colour2=blue"}" # Icon
	eleven="${11:-""}" # RESERVED

###########################################################################
#
# verify if auth token is valid
authToken=$(curl -su $six:$seven $jamfUrl/api/v1/auth/token -X POST)
apiToken=$( /usr/bin/plutil -extract token raw - <<< "$authToken" )

if [[ $authToken =~ "httpStatus\" : 401" ]]; then
	tokenState=false
	echo "[Error] failed to get authentification token!" >> ${commandFile}
	echo "[Error] verify api username and password, aswell as API permission!" >> ${commandFile}
	exit 1
else
	tokenState=true
	echo "[Success] successful get a authentification token!" >> ${commandFile}
	echo "[Success] api username and password, aswell as API permission are correct" >> ${commandFile}
fi

###########################################################################
#
# get device informations
deviceSerial=$(system_profiler SPHardwareDataType | grep Serial | awk '{print $NF}' )
jamfComputerID=$(/usr/bin/curl -H "Accept: text/xml" -sk -H "Authorization: Bearer $apiToken" "${jamfUrl}JSSResource/computers/serialnumber/${deviceSerial}" | xpath -e '/computer/general/id/text()')


###########################################################################
#
# log basic informations
echo "[info] jamfUrl: $jamfUrl" >> ${commandFile}
echo "[info] siteIDs: $four" >> ${commandFile}
echo "[info] script mode: $five" >> ${commandFile}
echo "[info] script titel: $eight" >> ${commandFile}
echo "[info] mainMessage: $nine" >> ${commandFile}
echo "[info] iconPath: $ten" >> ${commandFile}
echo "[info] deviceSerial: $deviceSerial" >> ${commandFile}
echo "[info] jamfComputerID: $jamfComputerID" >> ${commandFile}
#


###########################################################################
#
# functions
function getSiteIDsArray () {
				echo "[info] Get infos for all specified site IDs"  >> ${commandFile}
				IFS=',' read -r -a siteIDArray <<< "$four"
				for siteID in "${siteIDArray[@]}"; do  \
						apiEndpoint="${jamfUrl}JSSResource/sites/id/${siteID}"
						xmlData="<computer><general><site><id>${selectedSiteID}</id></site></general></computer>"
						siteName=$(curl -X GET -H "accept: application/xml" -sk -H "Authorization: Bearer $apiToken" "${apiEndpoint}" | xmllint --format --xpath '//site/name/text()' -)
						echo "[Success] site id $siteID name found: $siteName" >> ${commandFile}
						sitenames+="$siteID | $siteName,"
				done
				siteNames="${sitenames%,}"
				echo "[info] user available site names: $sitenames" >> ${commandFile}
}

function showUserInputWindow () {
				echo "[info] Show user site selection for specified site IDs with swiftDialog"  >> ${commandFile}
				button1text="OK"
				button2text="Cancel"
				dialogcmd=$(/usr/local/bin/dialog \
						--title "$eight" \
						--message "$nine" --messagefont size=18 \
						--icon "$ten" --ontop --small \
						--button1text "Specify selected site" \
						--button2text "Cancel" \
						--selecttitle "Required item",required --selectvalues "$siteNames" \
						--helpmessage "Without selecting the site, you didn´t get the correct configuration." \
						--timer 300 )
				
				#echo "$dialogcmd"
				selectTitleName=$(echo "$dialogcmd" &)
				SelectedOption=$(echo "$dialogcmd" | grep -o '"SelectedOption" : .*"' | cut -d ':' -f2- | sed 's/^[[:space:]]*//' | sed 's/"//g' &)
				selectedSiteID=$(echo "$SelectedOption" | cut -d '|' -f1 | tr -d ' ')
				selectedSiteName=$(echo "$SelectedOption" | cut -d '|' -f2 | tr -d ' ')
				
				if [ "$selectedSiteID" == "" ]; then
					echo "[Error] site selection was cancled or cloded" >> ${commandFile}
					exit 1
				else
					echo "[Success] selectedSiteID: $selectedSiteID" >> ${commandFile}
					echo "[Success] selectedSiteName: $selectedSiteName" >> ${commandFile}
				fi
}

function updateComputerSite () {
				echo "[Success] update computer id $jamfComputerID site id in Jamf Pro to: $selectedSiteID" >> ${commandFile}
				echo "[Success] update computer id $jamfComputerID site name in Jamf Pro to: $selectedSiteName" >> ${commandFile}
				apiEndpoint="${jamfUrl}JSSResource/computers/id/${jamfComputerID}"
				xmlData="<computer><general><site><id>${selectedSiteID}</id></site></general></computer>"
				curl -X PUT -H "Content-Type: text/xml" -sk -H "Authorization: Bearer $apiToken" -d "${xmlData}" "${apiEndpoint}"
}

function getComputerSiteold () {
				apiEndpoint="${jamfUrl}JSSResource/computers/serialnumber/${deviceSerial}"
				xmlData="<computer><general><site><id>${selectedSiteID}</id></site></general></computer>"
				jamfComputerSiteID=$(/usr/bin/curl -H "Accept: text/xml" -sk -H "Authorization: Bearer $apiToken" "${jamfUrl}JSSResource/computers/serialnumber/${deviceSerial}" | xpath -e '/computer/general/site/id/text()')
				jamfComputerSiteName=$(/usr/bin/curl -H "Accept: text/xml" -sk -H "Authorization: Bearer $apiToken" "${jamfUrl}JSSResource/computers/serialnumber/${deviceSerial}" | xpath -e '/computer/general/site/name/text()')
				echo "[Success] old computer site id in Jamf Pro to: $jamfComputerSiteID" >> ${commandFile}
				echo "[Success] old computer site name in Jamf Pro to: $jamfComputerSiteName" >> ${commandFile}
}

function getComputerSiteNew () {
				apiEndpoint="${jamfUrl}JSSResource/computers/serialnumber/${deviceSerial}"
				xmlData="<computer><general><site><id>${selectedSiteID}</id></site></general></computer>"
				jamfComputerSiteID=$(/usr/bin/curl -H "Accept: text/xml" -sk -H "Authorization: Bearer $apiToken" "${jamfUrl}JSSResource/computers/serialnumber/${deviceSerial}" | xpath -e '/computer/general/site/id/text()')
				jamfComputerSiteName=$(/usr/bin/curl -H "Accept: text/xml" -sk -H "Authorization: Bearer $apiToken" "${jamfUrl}JSSResource/computers/serialnumber/${deviceSerial}" | xpath -e '/computer/general/site/name/text()')
				echo "[Success] new computer site id in Jamf Pro to: $jamfComputerSiteID" >> ${commandFile}
				echo "[Success] new computer site name in Jamf Pro to: $jamfComputerSiteName" >> ${commandFile}
}

###########################################################################
#
# run the script

if [[ $five == "usermode" ]]; then
				getSiteIDsArray
				showUserInputWindow
				getComputerSiteold
				updateComputerSite
				getComputerSiteNew
	elif [[ $five == "bulk" ]]; then
				getSiteIDsArray
				selectedSiteID=$siteID
				getComputerSiteold
				updateComputerSite
				getComputerSiteNew
	else
				echo "[Error] unspecified mode selected" >> ${commandFile}
				exit 1
fi
invalidateTOKEN=$(curl --header "Authorization: Bearer ${authToken}" --write-out "%{http_code}" --silent --output /dev/null --request POST --url "$jamfUrl/api/v1/auth/invalidate-token")
echo "invalidateTOKEN: $invalidateTOKEN"

exit 0
