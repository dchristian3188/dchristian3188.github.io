[System.Management.Automation.Language.DynamicKeyword]::Reset()
$keyword = New-Object System.Management.Automation.Language.DynamicKeyword
$keyword.Keyword ="MetaData"
$keyword.BodyMode = [Management.Automation.Language.DynamicKeywordBodyMode]::HashTable
$keyword.NameMode =  [Management.Automation.Language.DynamicKeywordNameMode]::NoName
#$keyword.DirectCall = $true
#$keyword.ResourceName = 'IDK'
#$keyword.ImplementingModule = 'Microsoft.PowerShell.Management'
#$keyword.ImplementingModuleVersion  = '0.0.0.1'
$PARAM = New-Object System.Management.Automation.Language.DynamicKeywordParameter
$PARAM.Name="BoogersMcGee"
$keyword.Parameters.Add($PARAM.Name,$PARAM)
$prop = New-Object System.Management.Automation.Language.DynamicKeywordProperty
$prop.Name="BoogersMcGeez"
$prop.Mandatory = $true
$keyword.Properties.Add($prop.Name,$prop)

[System.Management.Automation.Language.DynamicKeyword]::AddKeyword($keyword)

[System.Management.Automation.Language.DynamicKeyword]::GetKeyword()


function MetaData
{
    param (
        [Parameter(Mandatory)]
        $KeywordData,       # Not used in this function....
        [Parameter(Mandatory)]
        [hashtable]
        $Value,             # The scriptblock that generates the configuration in each node.
        [Parameter(Mandatory)]
        $sourceMetadata     # Not used in this function
    )
    
    $PSBoundParameters
    
}


MetaData {
    BoogersMcGeez = 'aadsfa'
}