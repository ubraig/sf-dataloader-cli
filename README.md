# Command Line Interface for Salesforce Data Loader

## What is it?
A PowerShell module intended to simplify the usage of Scripted [Data Loader](https://developer.salesforce.com/tools/data-loader).

## Why would you need it?
The Salesforce Data Loader "as is" offers two ways of using it:
* Data Loader __GUI mode__ offers only limited options to save configuration settings for repetitive tasks.
* Data Loader __Scripting__ (a.k.a. "__Scripted Data Loader__") is quite complex to configure and rather unflexible for ad-hoc changes: It requires to write .xml  configuration files with the details of the operation to be executed.

This module is intended to fill the gap: You can run Salesforce Data Loader from of the PowerShell command line ([What is PowerShell?](https://learn.microsoft.com/en-us/powershell/scripting/overview)) for ad-hoc as well as for repetitive tasks:
* Provides a set of straightforward commands and easy-to-remember command aliases for all operations like __EXTRACT__, __INSERT__, __UPDATE__, __UPSERT__ and (HARD) __DELETE__.
* Easy to choose between __SOAP API__ or __Bulk API__ in either __serial__ or __parallel__ mode. Allows to set the __batch size__ via command line option.
* Auto-creates __mapping files__ in many scenarios.
* Encapsulates the handling of Salesforce authentication, e.g. 
    * by generating key files and encrypting passwords, i.e. the "username + password + security token" style,
    * optionally by using the authorization information as handled by the [Salesforce SFDX CLI](https://developer.salesforce.com/tools/sfdxcli).
* Supports all PowerShell standard features like help pages, tab completion for parameters, approved verb best practices etc.


## How does it look like?

A very basic example to copy Leads from one Org to another in 4 simple steps. 
For more examples and command reference see the [Wiki Pages](../../wiki)

### Step 1: Authorize the Source Org
In this  example we use the default org of your SFDX project:

`$MySourceOrg = sfauth`

### Step 2: Authorize the Target Org
In this example for a Sandbox org we will give the username and have the password and security token prompted via console input: 

`$MyTargetOrg = sfauth MyUserName@MyCompanyName.com -ConsoleInput -InstanceUrl https://test.salesforce.com`

### Step 3: Extract all Lead Records from Source Org
Simple example to extract all Leads to a default target file 'Lead.csv':

`sfextract $MySourceOrg Lead "SELECT Id, FirstName, LastName, Company FROM Lead"`

### Step 4: Insert all Leads to Target Org
Simple example to import those Leads from the default source file 'Lead.csv' to another org. A default Data Loader mapping file (.sdl) ist automatically created on the fly from the column headers in the .csv file:

`sfinsert $MyTargetOrg Lead`

## How to get it?

### Prerequisites
Mandatory
- Windows 10 or newer with __PowerShell v5.1__ or newer. NOTE: v5.1 is already installed by default on Windows 10 and newer. For further details see [Installing Windows PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/windows-powershell/install/installing-windows-powershell?view=powershell-7.3)
- A __Java Runtime Environment (JRE)__ version 11 or later as described in [Considerations for Installing Data Loader](https://developer.salesforce.com/docs/atlas.en-us.dataLoader.meta/dataLoader/installing_the_data_loader.htm), e.g. [Zulu OpenJDK](https://www.azul.com/downloads/zulu-community/?package=jdk). Make sure that the __JAVA_HOME__ environment variable is set properly.
- A download of the latest __Salesforce Data Loader .zip file__ from https://developer.salesforce.com/tools/data-loader or from https://github.com/forcedotcom/dataloader/releases. __NOTE:__ There is no need to run the installation batch file from inside the .zip. This would only be needed if you also want to use Data Loader independently of the SfDataloaderCli module.
- Make sure, you have got the proper permissions in your Salesforce Org as described in [Salesforce Data Loader Installation Considerations](https://developer.salesforce.com/docs/atlas.en-us.dataLoader.meta/dataLoader/installing_the_data_loader.htm).

Optionally
- [Salesforce CLI](https://developer.salesforce.com/tools/sfdxcli) if you want to use the authentication methods provided by SFDX.

### Download and Install SfDataloaderCli PowerShell Module
- Download the .zip file of the latest stable version from [Releases](../../releases).
- Extract the files to a target directory of your choice, e.g. `D:\sf-dataloader-cli-0.0.1-beta`
- From the Data Loader .zip file (see prerequisites above), locate the Data Loader .jar file: e.g. in the `dataloader_v58.0.2.zip` this would be the file `dataloader_v58.0.2.jar`.
- Copy this .jar file to the corresponding directory in the PowerShell module directory, e.g. to `D:\sf-dataloader-cli-0.0.1-beta\dataloader`

### Import the SfDataloaderCli module into your PowerShell session
- Open a PowerShell console window.
- Run `Import-Module D:\sf-dataloader-cli-0.0.1-beta\dataloader\SfDataloaderCli.psd1`.

## Get Started!

See the [Wiki Pages](../../wiki) on how to get started.

