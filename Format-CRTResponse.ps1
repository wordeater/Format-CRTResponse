function Format-CRTResponse {
	<#	
	.SYNOPSIS
		Formats a query response from https://crt.sh into a simple array of strings.
	
	.FUNCTIONALITY
		Network
	
	.DESCRIPTION
		Certificates are deposited in public, transparent logs. Certificate logs are append-only ledgers of certificates. Because they're distributed and independent, anyone can query them to see what certificates have been included and when. Because they're append-only, they are verifiable by Monitors. Organisations and individuals with the technical skills and capacity can run a log.
		
		This function queries the public logs using the web front end located at https://crt.sh
		
		By default, the function performs no deduplication and includes all entries, even those that are expired.
		It also has a default sleep of 5 seconds when a web error occurs and it must retry a request.
		These option can be changed using parameters.
		
		The input is the response from a query against https://crt.sh and is in the format of an array of strings which is converted into an array of hashes with some post-processing.
		[			
			{
				"issuer_ca_id": 16418,
				"issuer_name": "C=US, O=Let's Encrypt, CN=Let's Encrypt Authority X3",
				"common_name": "icheck.lbapps.com",
				"name_value": "icheck.lbapps.com",
				"id": 3616206571,
				"entry_timestamp": "2020-11-07T16:46:43.456",
				"not_before": "2020-11-07T15:46:43",
				"not_after": "2021-02-05T15:46:43",
				"serial_number": "03ffeea57322e24cd6fd207682f59ead324f"
			},
			{
				"issuer_ca_id": 13,
				"issuer_name": "C=ZA, ST=Western Cape, L=Cape Town, O=Thawte Consulting cc, OU=Certification Services Division, CN=Thawte Premium Server CA, emailAddress=premium-server@thawte.com",
				"common_name": "icheck.lbapps.com",
				"name_value": "icheck.lbapps.com",
				"id": 1451857,
				"entry_timestamp": "2013-04-23T11:19:42.045",
				"not_before": "2008-09-03T00:00:00",
				"not_after": "2011-10-28T23:59:59",
				"serial_number": "62d0a79bc5b32f9953489598013637d6"
			}
		]
		Post-processing does the following
		- Converts issuer_name to an array of hashes
		- Converts issuer_name.OU from an array to '|' separated data
		- Converts name_value to '|' separated data instead of '\n' separated data
		- Converts entry_timestamp to a DateTime
		- Converts not_before to a DateTime
		- Converts not_after to a DateTime
		Which can be sent to Export-Csv with a ForEach command.
	
	.PARAMETER CRTResponse
		An array containing the responses from a query against https://crt.sh
	
	.OUTPUTS
		System.Array
	
	.EXAMPLE
		Invoke-RestMethod -Method "Get" -Uri "https://crt.sh/?q=linkedin.com&output=json&deduplicate=Y&exclude=expired" | Format-CRTResponse
		
	.EXAMPLE
		$Response = Invoke-RestMethod -Method "Get" -Uri "https://crt.sh/?q=microsoft.com&output=json&deduplicate=Y&exclude=expired"
		$Response | Format-CRTResponse | ForEach-Object { $_ | Export-Csv .\Temp.csv -Force -Append -NoType }

	.EXAMPLE
		$Response = Invoke-CRTRequest -Domain "google.com" -Delay 15 -Retry 5
		Format-CRTResponse -CRTResponse $Response
	
	.NOTES
		Written by Word Eater (WordEaterNG@gmail.com)
		
		Tested on Windows Server and Linux
		
		Certificate Transparency Search Page - https://crt.sh/
		How Certificate Transparency Works - https://certificate.transparency.dev/howctworks/
		
		Used to convert a string into an array
			https://stackoverflow.com/questions/15927291/how-to-split-a-string-by-comma-ignoring-comma-in-double-quotes
			
		Version History
		v1.0-20230306	Initial release

	.LINK
		https://crt.sh/

	.LINK
		https://certificate.transparency.dev/

	.LINK
		https://certificate.transparency.dev/howctworks/
	#>
	[CmdletBinding(SupportsShouldProcess = $true)]
	[OutputType([System.Array])]
	Param(
		[Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)][Array]$CRTResponse=@()
	) # end of parameter
	
	Begin {
		# creating helper function
		function Get-TimeStamp {
			$TimeStamp = "[{0:yyyy-MM-dd} {0:HH:mm:ss}]" -f (Get-Date)
			return $TimeStamp
		}
		$StartDateTime = Get-Date
	} # end of Begin
	
	Process {
		$($(Get-Timestamp) + "`t" + "Processing response:`r`n" + $($CRTResponse | ConvertTo-Json -Depth 8)) | Write-Debug
		$CRTResponse | ForEach {
			$entry = $_
			$issuer = $([regex]::Split($entry.issuer_name, ',(?=(?:[^"]|"[^"]*")*$)' ) | ForEach { $_.Trim() } ) | ConvertFrom-StringData
			$OutputRow = [PSCustomObject][ordered]@{
				common_name = $entry.common_name
					name_value = ((($entry.name_value -Split '\n') | Sort-Object -Unique) -Join '|' )
				id = $entry.id
				entry_timestamp = Get-Date -Date $entry.entry_timestamp
				not_before = Get-Date -Date $entry.not_before
				not_after = Get-Date -Date $entry.not_after
				serial_number = $entry.serial_number
				issuer_ca_id = $entry.issuer_ca_id
				issuer_name = $entry.issuer_name
				"issuer.CommonName" = $issuer.CN -Replace '"',''
				"issuer.CountryName" = $issuer.C -Replace '"',''
				"issuer.StateorProvinceName" = $issuer.ST -Replace '"',''
				"issuer.Locality" = $issuer.L -Replace '"',''
				"issuer.Organization" = $issuer.O -Replace '"',''
				"issuer.OrganizationalUnit" = ($issuer.OU -Join '|') -Replace '"',''
				"issuer.serialNumber" = $issuer.serialNumber
				"issuer.emailAddress" = $issuer.emailAddress
			}
			return $OutputRow
		} # end of ForEach entry in the Response
	} # end of Process
	
	End {
		$EndDateTime = Get-Date
		$Duration = New-TimeSpan -Start $StartDateTime -End $EndDateTime
		$(Get-Timestamp) + "`t" + "Execution took $Duration" | Write-Debug
	} # end of End
	
} # end of function Format-CRTResponse
