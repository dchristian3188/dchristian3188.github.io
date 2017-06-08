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


$tokens = [System.Management.Automation.PSParser]::Tokenize($sb.ToString(),[ref]$null)

$tokens | Group type

$tokens.Where{$PSItem.Type -eq 'keyword'}






$ast = [System.Management.Automation.Language.Parser]::ParseInput($sb.ToString(),[ref]$null,[ref]$null)
$ast.FindAll({$args[0] -is [System.Management.Automation.Language.BlockStatementAst]},$true)

$tokens = [System.Management.Automation.PSParser]::Tokenize($ast.ToString(),[ref]$null)
$tokens.Where{$PSItem.Type -eq 'keyword'} | GM