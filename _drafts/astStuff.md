$sb = {
    function Do-Thing
    {
        param($Name)
    }

    Do-Thing -Name 'booger'
    Write-Verbose -Message "testing 123"
}

$ast = [System.Management.Automation.Language.Parser]::ParseInput($sb.ToString(),[ref]$null,[ref]$null)
$ast.FindAll({$args[0] -is [System.Management.Automation.Language.StatementAst]},$true)