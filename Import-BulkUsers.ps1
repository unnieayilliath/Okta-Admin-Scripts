#import the OktaAPI module
Import-Module OktaAPI
Connect-Okta "<API Token>" "https://tenant.okta.com"
function Import-BulkUsers($csvPath) {
        $users = Import-Csv $csvPath
        $resultsArray = @()
        foreach ($user in $users) {
            Write-Host "Creating user for"  $user.login
            $profile = @{login = $user.login; email = $user.email; firstName = $user.firstName; lastName = $user.lastName}
            $userCreationStatus = ""
            $groupAssignmentStatus=""
            $ErrorMessage=""
            try {
                if($user.password){
                    # create user with password
                    $oktaUser = New-OktaUser @{profile = $profile; credentials = @{password = @{value = $user.password}}} $true
                }else{
                    # create user without password
                    $oktaUser = New-OktaUser @{profile = $profile} $true
                }
                Write-Host "Created user for"  $user.login -ForegroundColor Green
                $userCreationStatus="Success"
            } catch {
                try {
                    # check if user exists
                    $oktaUser = Get-OktaUser $user.login
                    Write-Host  $user.login " already exists!" -ForegroundColor Yellow
                    $userCreationStatus="Exists"
                } catch {
                    #capture error message
                    $ErrorMessage = $_.Exception.Message
                    $oktaUser = $null
                    $userCreationStatus = "Failed"
                    Write-Host "Failed for "  $user.login -ForegroundColor Red
                }
            }
            if ($oktaUser) {
                try {
                    if($user.groupId){
                        Add-OktaGroupMember $user.groupId $oktaUser.id
                        $groupAssignmentStatus="Success"
                        Write-Host "Add user to group" -ForegroundColor Green
                    }
                } catch {
                    $groupAssignmentStatus = "Failed"
                    $ErrorMessage = $_.Exception.Message
                    Write-Host "Failed adding user to group." -ForegroundColor Red
                }
            }
            $resultsArray += [PSCustomObject]@{
                id=$oktaUser.id;
                firstName= $user.firstName;
                lastName=$user.lastName;
                login = $user.login;
                userCreationStatus = $userCreationStatus;
                groupAssignment= $groupAssignmentStatus;
                ErrorMessage=$ErrorMessage
            }
        }
        $resultsArray | Export-Csv ImportBulkUsers-Result.csv
    }
Import-BulkUsers TestUsers.csv
