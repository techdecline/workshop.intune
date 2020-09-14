param (
    $UserArr = (Import-Csv -path ".\comedia_users_kevin.txt" -Delimiter "," -Header Surname,GivenName,mail),
    $DomainName = "M365x852250.onmicrosoft.com",
    $UsageLocation = "DE",
    [pscredential]$AzureAdCredential = (Get-Credential)

)

function Test-PasswordComplexity {
    param (
        [String]$Password
    )
    If (
                 ($Password -cmatch "[A-Z\p{Lu}\s]") `
            -and ($Password -cmatch "[a-z\p{Ll}\s]") `
            -and ($Password -match "[\d]") `
            -and ($Password -match "[^\w]")  
        ) { 
        return $true
    }
    else {
        return $true
    }
}

Import-module -Name AzureAD
Connect-AzureAD -Credential $AzureAdCredential

$resultArr = [System.Collections.ArrayList]@()

foreach ($userObj in $UserArr) {
    $upn = ($userObj.GivenName.Substring(0,1) + $userObj.Surname.Substring(0,6) + "@" + $DomainName).ToLower()
    $adminUpn = ("a-" + $userObj.GivenName.Substring(0,1) + $userObj.Surname.Substring(0,5) + "@" + $DomainName).ToLower()
    
    # Create random password until required complexity is reached.
    $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    do {
        $PasswordProfile.Password = [System.IO.Path]::GetRandomFileName()
    } while (-not (Test-PasswordComplexity -Password $PasswordProfile.Password))

    
    $userParamHash = @{
        UserPrincipalName = $upn.ToLower()
        GivenName = $userObj.GivenName
        SurName = $userObj.Surname
        PasswordProfile = $PasswordProfile
        AccountEnabled = $true
        DisplayName = $userObj.GivenName
        MailNickName = $userObj.GivenName
        UsageLocation = $UsageLocation
    }
    
    $adminParamHash = @{
        UserPrincipalName = $adminUpn
        GivenName = $userObj.GivenName
        SurName = $userObj.Surname
        PasswordProfile = $PasswordProfile
        AccountEnabled = $true
        DisplayName = "admin" + $userObj.GivenName
        MailNickName = "admin" + $userObj.GivenName
        UsageLocation = $UsageLocation
    }

    $adminUpn
    $upn
    $azUserObj = New-AzureADUser @userParamHash
    $azAdminObj = New-AzureADUser @adminParamHash

    $rtnObj = $userObj | Select-Object *,@{Name = "UPN";Expression = {$upn}},@{Name = "Admin UPN";Expression = {$adminupn}},@{Name = "Password";Expression = {$PasswordProfile.Password}}
    $resultArr.Add($rtnObj) | Out-Null
}

$resultArr | Export-Csv -Path .\accounts_kevin.csv -NoTypeInformation