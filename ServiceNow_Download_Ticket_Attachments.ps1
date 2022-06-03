param(
[string]$number,
[string]$path="C:\Users\$($env:username)\Downloads"
)

Function get-ticketinfo($SNTable,$number){
$URL = "{2}/api/now/table/{0}?sysparm_query=number={1}&sysparm_fields=sys_id,number,short_description" -f $SNTable,$number,$BaseURL
$CMDBSN = Invoke-WebRequest -Uri $URL -Headers $Headers
if ($CMDBSN.statusdescription -eq "OK") {
	$registro = ($CMDBSN.content | convertfrom-json).result
	return $registro
	}
}
Function get-attachmentmetadata($SNtable,$sys_id){
	$URL = "{2}/api/now/table/sys_attachment?table_name={0}&table_sys_id={1}" -f $SNTable,$sys_id,$BaseURL
	$CMDBSN = Invoke-WebRequest -Uri $URL -Headers $Headers
	if ($CMDBSN.statusdescription -eq "OK") {
		$registro = ($CMDBSN.content | convertfrom-json).result
		return $registro
		}
}
##### your company info ######
$BaseURL="https://my_tenant.service-now.com:443"
$pair = "username:password"
##############################
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$Headers = @{
	Authorization = $basicAuthValue
}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

while(-not $number){
	$number=read-host "ticket number?"
	}
switch -regex($number){
"^INC"{$SNTable="incident"}
"^SCTASK"{$SNTable="sc_task"}
"^RITM"{$SNTable="sc_req_item"}
"^REQ"{$SNTable="sc_request"}
"^DMND"{$SNTable="dmn_demand"}
default{exit}
}
$ticketInfo=get-ticketinfo $SNTable $number
if($ticketInfo){
	$ticketInfo|fl *	
	$localpath="{0}\{1} - {2}" -f $path,$ticketInfo.number, ($ticketInfo.short_description -replace "[\\/:*?<>|]").trim()
	if (!(test-path $localpath)) { New-item -ItemType Directory -path $localpath | out-null }
	$metadata=get-attachmentmetadata $SNTable $ticketinfo.sys_id
	foreach($m in $metadata){
		'{0} {1} {2:N2}MB' -f $m.file_name,$m.content_type,($m.size_bytes/1MB)|out-host
		$URL = "{1}/api/now/attachment/{0}/file" -f $m.sys_id,$BaseURL
		$response = Invoke-RestMethod -Headers $headers -Method "GET" -Uri $URL -OutFile "$localpath\$($m.file_name)"

	}
}else{'Ticket not found'|write-host -fore red}
