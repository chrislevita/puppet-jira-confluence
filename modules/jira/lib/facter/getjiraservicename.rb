Facter.add(:getjiraservicename) do
  setcode do
      result =''
    	# ATL service disply name is always "Atlassian JIRA"
  		# exec to call win cmd sc and find Service Name
    	keyName = Facter::Util::Resolution.exec("sc getkeyname \"Atlassian JIRA\" | findstr /r /i /m \"\\<NAME.*\\>\"")
    	# ruby code, gsub to clean the return
    	result += ((keyName.gsub(/(Name =)/, '')).lstrip).rstrip 
  end
end

# ".gsub(/([aeiou])/, '<\1>')       
    	# a[/[aeiou](.)\1/]
    	# result = regsubst($str,'^(DISPLAY_NAME:).(.*)$', '\2')
    	# result
    	
# $i3 = regsubst($ipaddress,'^(\d+)\.(\d+)\.(\d+)\.(\d+)$','\3')
# DISPLAY_NAME: Atlassian JIRA


# sc queryex type= service state= all | findstr /r /i /m "\<JIRA.*\>"
# >sc getkeyname "Atlassian JIRA" | findstr /r /i /m "\<NAME.*\>"