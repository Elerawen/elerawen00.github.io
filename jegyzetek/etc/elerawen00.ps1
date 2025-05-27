# Define empty functions for menu options
function setup_timezone {
    W32tm /config /manualpeerlist:"0.hu.pool.ntp.org 1.hu.pool.ntp.org 2.hu.pool.ntp.org 3.hu.pool.ntp.org" /syncfromflags:manual /reliable:yes /update
    Set-TimeZone -Name "Central Europe Standard Time"
    W32tm /resync /force
    Get-TimeZone
    Read-Host "Nyomj Enter-t a kilepeshez"
}

function setup_ip {
    # Function to convert subnet mask to prefix length
    function ConvertTo-SubnetPrefixLength {
        param (
            [string]$subnetMask
        )
        
        $binaryMask = [Convert]::ToString([IPAddress]::Parse($subnetMask).Address, 2).PadLeft(32, '0')
        return ($binaryMask -split '1').Length - 1
    }

    # Get the name of the network adapter
    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    if (-not $adapter) {
        Write-Host "No active network adapter found."
        exit
    }

    # Prompt for IP address, subnet mask, default gateway, and preferred DNS
    $ipAddress = Read-Host "Enter the IP address"
    $subnetMask = Read-Host "Enter the Subnet Mask"
    $defaultGateway = Read-Host "Enter the Default Gateway"
    $preferredDNS = Read-Host "Enter the Preferred DNS Server"

    # Configure the static IP address and subnet mask
    try {
        $prefixLength = ConvertTo-SubnetPrefixLength $subnetMask
        New-NetIPAddress -InterfaceAlias $adapter.Name -IPAddress $ipAddress -PrefixLength $prefixLength -DefaultGateway $defaultGateway -ErrorAction Stop
        Write-Host "IP address and subnet mask configured successfully."
    } catch {
        Write-Host "Failed to set IP address and subnet mask: $_"
    }

    # Configure the preferred DNS server
    try {
        Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses $preferredDNS -ErrorAction Stop
        Write-Host "Preferred DNS server configured successfully."
    } catch {
        Write-Host "Failed to set preferred DNS server: $_"
    }
    Read-Host "Nyomj Enter-t a kilepeshez"
}

function computer_name_and_description {
    # Function to set the computer name and description
    function Set-ComputerDetails {
        # Prompt for computer name
        $newComputerName = Read-Host "Enter the new computer name"

        # Prompt for computer description
        $description = Read-Host "Enter the computer description"

        # Set the new computer name
        try {
            Rename-Computer -NewName $newComputerName -Force -ErrorAction Stop
            Write-Host "Computer name changed to: $newComputerName"
        } catch {
            Write-Host "Failed to change computer name: $_"
        }

        # Set the computer description
        try {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "RegisteredOwner" -Value $description -ErrorAction Stop
            Write-Host "Computer description set to: $description"
        } catch {
            Write-Host "Failed to set computer description: $_"
        }

        # Prompt for domain name
        $domainName = Read-Host "Enter the domain name to join (leave empty to skip)"

        if (![string]::IsNullOrWhiteSpace($domainName)) {
            # Add to domain if a domain name is provided
            try {
                $credential = Get-Credential -Message "Enter credentials for domain $domainName"
                Add-Computer -DomainName $domainName -Credential $credential -Force -ErrorAction Stop
                Write-Host "Successfully added to domain: $domainName"
            } catch {
                Write-Host "Failed to add to domain: $_"
            }
        } else {
            Write-Host "No domain name provided. Skipping domain addition."
        }
    }

    # Call the function
    Set-ComputerDetails
    Read-Host "Nyomj Enter-t a kilepeshez"
}

function setup_AD {
    Import-Module ActiveDirectory

    # Script kezdete
    
    # Bekérjük a domain nevet és a fő szervezeti egység nevét a felhasználótól
    $domain = Read-Host "Kerem adja meg a domain nevet (pl. example.com)"
    $mainOU = Read-Host "Kerem adja meg a fo szervezeti egyseg nevet (pl. example)"
    
    # Szervezeti egységek és szükséges felhasználók száma
    $organizationalUnits = @(
        @{ Name = "Ugyvezeto Igazgato"; UserCount = 1; GroupName = "managing_director" },
        @{ Name = "Konyvelo"; UserCount = 1; GroupName = "accountant" },
        @{ Name = "Gazdasagi osztaly"; UserCount = 1; GroupName = "finance_department" },
        @{ Name = "Marketing osztaly"; UserCount = 1; GroupName = "marketing_department" },
        @{ Name = "IT osztaly"; UserCount = 1; GroupName = "it_department" },
        @{ Name = "Tanulmanyi osztaly"; UserCount = 2; GroupName = "academic_department" },
        @{ Name = "Oktatok"; UserCount = 3; GroupName = "teachers" },
        @{ Name = "Tanulok"; UserCount = 5; GroupName = "students" }
    )
    
    # Generáláshoz szükséges minta nevek
    $firstNames = @("Michael", "Anna", "John", "Emily", "Paul", "Jessica", "George", "Sarah", "Tom", "Linda")
    $lastNames = @("Smith", "Johnson", "Williams", "Jones", "Brown", "Davis", "Miller", "Wilson", "Taylor", "Clark")
    
    # Minden szervezeti egység létrehozása
    foreach ($ou in $organizationalUnits) {
        $ouName = $ou.Name
        $groupName = $ou.GroupName
        $ouUserCount = $ou.UserCount
    
        # Teljes OU elérési út létrehozása
        $ouPath = "OU=$ouName,OU=$mainOU,DC=$($domain -replace '\.', ',DC=')"
    
        # OU létrehozása, ha nem létezik
        if (-not (Get-ADOrganizationalUnit -Filter { DistinguishedName -eq $ouPath } -ErrorAction SilentlyContinue)) {
            Write-Host "Letrehozom az OU-t: $ouName"
            New-ADOrganizationalUnit -Name $ouName -Path "OU=$mainOU,DC=$($domain -replace '\.', ',DC=')"
        } else {
            Write-Host "Az OU mar letezik: $ouName"
        }
    
        # Csoport létrehozása az OU-ban
        $groupDN = "CN=$groupName,OU=$ouName,OU=$mainOU,DC=$($domain -replace '\.', ',DC=')"
        if (-not (Get-ADGroup -Filter { DistinguishedName -eq $groupDN } -ErrorAction SilentlyContinue)) {
            Write-Host "Letrehozom a csoportot: $groupName"
            New-ADGroup -Name $groupName -GroupScope Global -Path $ouPath -GroupCategory Security
        } else {
            Write-Host "A csoport mar letezik: $groupName"
        }
    
        # Felhasználók létrehozása és hozzáadása a csoporthoz
        for ($i = 1; $i -le $ouUserCount; $i++) {
            $usernameExists = $true
            while ($usernameExists) {
                # Random név generálása
                $firstName = $firstNames | Get-Random
                $lastName = $lastNames | Get-Random
                $username = ($firstName.Substring(0, 1) + "_" + $lastName).ToLower()
    
                # Ellenőrizze, hogy a felhasználónév már létezik-e
                if (-not (Get-ADUser -Filter { SamAccountName -eq $username } -ErrorAction SilentlyContinue)) {
                    $usernameExists = $false
                }
            }
    
            # Teljes név beállítása
            $fullName = "$firstName $lastName"
    
            # Felhasználó létrehozása
            $password = ConvertTo-SecureString -String "Passw0rd" -AsPlainText -Force
            $userPath = "OU=$ouName,OU=$mainOU,DC=$($domain -replace '\.', ',DC=')"
    
            Write-Host "Felhasznalo letrehozasa: $username az OU-ban: $ouName"
    
            New-ADUser -SamAccountName $username `
                       -UserPrincipalName "$username@$domain" `
                       -Name $fullName `
                       -GivenName $firstName `
                       -Surname $lastName `
                       -DisplayName $fullName `
                       -PasswordNeverExpires $true `
                       -Enabled $true `
                       -AccountPassword $password `
                       -Path $userPath `
                       -ChangePasswordAtLogon $false `
                       -PassThru
    
            # Felhasználó hozzáadása a csoporthoz
            Add-ADGroupMember -Identity $groupName -Members $username
            Write-Host "Felhasznalo $username sikeresen letrehozva es hozzaadva a csoporthoz: $groupName"
        }
    }

    Read-Host "Nyomj Enter-t a kilepeshez"
}

function ExitMenu {
    Write-Host "Kilepes..."
    exit
}

# Function to display the menu
function Show-Menu {
    Clear-Host
    Write-Host "====================================================================================="
    Write-Host @"

    _____ _     _____ ____      ___        _______ _   _  ___   ___   ____  ____  _ 
    | ____| |   | ____|  _ \    / \ \      / / ____| \ | |/ _ \ / _ \ |  _ \/ ___|/ |
    |  _| | |   |  _| | |_) |  / _ \ \ /\ / /|  _| |  \| | | | | | | || |_) \___ \| |
    | |___| |___| |___|  _ <  / ___ \ V  V / | |___| |\  | |_| | |_| ||  __/ ___) | |
    |_____|_____|_____|_| \_\/_/   \_\_/\_/  |_____|_| \_|\___/ \___(_)_|   |____/|_|
                                                                                     
         
"@
    Write-Host "====================================================================================="
    Write-Host "[1] Idozona beallitas"
    Write-Host "[2] IP cim beallitas"
    Write-Host "[3] Gep elnevezese"
    Write-Host "[4] Active Directory Setup"
    Write-Host "[0] Kilepes"
    Write-Host "=========================="
}

# Main loop
while ($true) {
    Show-Menu
    $choice = Read-Host "Valassz [0-4] "

    switch ($choice) {
        '1' { setup_timezone }
        '2' { setup_ip }
        '3' { computer_name_and_description }
        '4' { setup_AD }
        '0' { ExitMenu }
        default { Write-Host "Nincs ilyen opcio. Probald ujra!" }
    }
}
