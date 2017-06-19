$keyword = New-Object System.Management.Automation.Language.DynamicKeyword
$keyword.Keyword ="MetaData"
$keyword.BodyMode = [Management.Automation.Language.DynamicKeywordBodyMode]::HashTable
$keyword.NameMode =  [Management.Automation.Language.DynamicKeywordNameMode]::NoName
$keyword.DirectCall = $true
$prop = New-Object System.Management.Automation.Language.DynamicKeywordProperty
$prop.Name="BoogersMcGee"
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
        [ScriptBlock]
        $Value,             # The scriptblock that generates the configuration in each node.
        [Parameter(Mandatory)]
        $sourceMetadata     # Not used in this function
    )

    $PSBoundParameters
}

 Metadata {
     BoogersMcGee = "Monkey"
 }