# Format-CRTResponse

## NAME
`Format-CRTResponse`

## SYNOPSIS
Formats a query response from https://crt.sh into a simple array of strings.

## DESCRIPTION
Certificates are deposited in public, transparent logs. Certificate logs are append-only ledgers of certificates. Because they're distributed and independent, anyone can query them to see what certificates have been included and when. Because they're append-only, they are verifiable by Monitors. Organisations and individuals with the technical skills and capacity can run a log.
		
This function queries the public logs using the web front end located at https://crt.sh
		
By default, the function performs no deduplication and includes all entries, even those that are expired.
It also has a default sleep of 5 seconds when a web error occurs and it must retry a request.
These option can be changed using parameters.
		
The input is the response from a query against https://crt.sh and is in the format of an array of strings which is converted into an array of hashes with some post-processing.
The following section shows the format in which https://crt.sh returns results as JSON.
```
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
```

Post-processing does the following
- Converts `issuer_name` to an `array` of `hashes`
- Converts `issuer_name.OU` from an `array` to a `|` separated `string`
- Converts `name_value` to a `|` separated `string` instead of a `\n` separated `string`
- Converts `entry_timestamp` to a `DateTime`
- Converts `not_before` to a `DateTime`
- Converts `not_after` to a `DateTime`

After post-processing, the data looks like this.
```
[
  {
    "search_domain": "icheck.lbapps.com",
    "common_name": "icheck.lbapps.com",
    "name_value": "icheck.lbapps.com",
    "id": 3616204835,
    "entry_timestamp": "2020-11-07T16:46:43.817",
    "not_before": "2020-11-07T15:46:43",
    "not_after": "2021-02-05T15:46:43",
    "serial_number": "03ffeea57322e24cd6fd207682f59ead324f",
    "issuer_ca_id": 16418,
    "issuer_name": "C=US, O=Let's Encrypt, CN=Let's Encrypt Authority X3",
    "issuer.CommonName": "Let's Encrypt Authority X3",
    "issuer.CountryName": "US",
    "issuer.StateorProvinceName": "",
    "issuer.Locality": "",
    "issuer.Organization": "Let's Encrypt",
    "issuer.OrganizationalUnit": "",
    "issuer.serialNumber": null,
    "issuer.emailAddress": null
  },
  {
    "search_domain": "icheck.lbapps.com",
    "common_name": "icheck.lbapps.com",
    "name_value": "icheck.lbapps.com",
    "id": 1451857,
    "entry_timestamp": "2013-04-23T11:19:42.045",
    "not_before": "2008-09-03T00:00:00",
    "not_after": "2011-10-28T23:59:59",
    "serial_number": "62d0a79bc5b32f9953489598013637d6",
    "issuer_ca_id": 13,
    "issuer_name": "C=ZA, ST=Western Cape, L=Cape Town, O=Thawte Consulting cc, OU=Certification Services Division, CN=Thawte Premium Server CA, emailAddress=premium-server@thawte.com",
    "issuer.CommonName": "Thawte Premium Server CA",
    "issuer.CountryName": "ZA",
    "issuer.StateorProvinceName": "Western Cape",
    "issuer.Locality": "Cape Town",
    "issuer.Organization": "Thawte Consulting cc",
    "issuer.OrganizationalUnit": "Certification Services Division",
    "issuer.serialNumber": null,
    "issuer.emailAddress": "premium-server@thawte.com"
  }
]
```
where each `element` of the `array` is a `PSCustomObject` like this:
```
   TypeName: System.Management.Automation.PSCustomObject

Name                       MemberType   Definition
----                       ----------   ----------
Equals                     Method       bool Equals(System.Object obj)
GetHashCode                Method       int GetHashCode()
GetType                    Method       type GetType()
ToString                   Method       string ToString()
common_name                NoteProperty string common_name=icheck.lbapps.com
entry_timestamp            NoteProperty System.DateTime entry_timestamp=4/14/2021 6:12:18PM
id                         NoteProperty long id=4375279246
issuer.CommonName          NoteProperty string issuer.CommonName=R3
issuer.CountryName         NoteProperty string issuer.CountryName=US
issuer.emailAddress        NoteProperty object issuer.emailAddress=null
issuer.Locality            NoteProperty string issuer.Locality=
issuer.Organization        NoteProperty string issuer.Organization=Let's Encrypt
issuer.OrganizationalUnit  NoteProperty string issuer.OrganizationalUnit=
issuer.serialNumber        NoteProperty object issuer.serialNumber=null
issuer.StateorProvinceName NoteProperty string issuer.StateorProvinceName=
issuer_ca_id               NoteProperty long issuer_ca_id=183267
issuer_name                NoteProperty string issuer_name=C=US, O=Let's Encrypt, CN=R3
name_value                 NoteProperty string name_value=icheck.lbapps.com
not_after                  NoteProperty System.DateTime not_after=7/13/2021 5:12:18PM
not_before                 NoteProperty System.DateTime not_before=4/14/2021 5:12:18PM
search_domain              NoteProperty string search_domain=icheck.lbapps.com
serial_number              NoteProperty string serial_number=033225df1dffc2523e5cd3615c2b6c20eeb5
```

File output can be sent to `Export-Csv` with a `ForEach` command.
```
