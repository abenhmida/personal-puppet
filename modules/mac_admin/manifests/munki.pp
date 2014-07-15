# == Class: mac_admin::munki
#
# Installs Munki and installs a configuration profile with Munki settings
#
# === Parameters
#
# [*repourl*]
#   The URL of your Munki repo. Defaults to http://munki
#
# [*clientidentifier*]
#   The Mac's clientidentifier. Defaults to the Mac's serial number
#
# [*suppressautoinstall*]
#   Suppress auto installation of packages. Defaults to false
#
# [*suppress_stop*]
#   Suppress the stop button during installation. Defaults to true
#
# [*install_apple_updates*]
#   Allows Munki to install Apple Software Updates Defaults to false
#
# [*bootstrap*]
#   Touch /Users/Shared/.com.googlecode.munki.checkandinstallatstartup when the Munki package is changed. Defaults to false
#
# === Examples
#
#  class { 'mac_admin::munki':
#    repourl                     => "http://munki.example.com",
#    suppressstopbuttononinstall => true,
#    bootstrap                   => true,
#    clientidentifier            => "demo_client",
#  }
#

class mac_admin::munki(
    $repourl = $mac_admin::params::repourl,
    $clientidentifier = $mac_admin::params::clientidentifier,
    $suppressautoinstall = $mac_admin::params::suppressautoinstall,
    $suppress_stop = $mac_admin::params::suppress_stop,
    $bootstrap = $mac_admin::params::bootstrap,
    $install_apple_updates = $mac_admin::params::install_apple_updates,
    $packageurl = $mac_admin::params::packageurl,
    $catalogurl = $mac_admin::params::catalogurl,
    $manifesturl = $mac_admin::params::manifesturl,
    $additionalhttpheaders = $mac_admin::params::additionalhttpheaders,
    ) inherits mac_admin::params {

    ## Install the latest Munki
    package { 'munki_tools':
        ensure   => installed,
        provider => pkgdmg,
        source   => 'https://munki.googlecode.com/files/munkitools-1.0.0.1864.0.dmg',
    }

    if ! defined(File['/var/lib/puppet/mac_admin']) {
        file { '/var/lib/puppet/mac_admin':
            ensure => directory,
        }
    }

    ##Write out the contents of the template to a mobileconfig file

    file {'/var/lib/puppet/mac_admin/com.grahamgilbert.munkiprefs.mobileconfig':
        content => template('mac_admin/com.grahamgilbert.munkiprefs.erb'),
        owner   => 0,
        group   => 0,
        mode    => '0755',
    }

    ##Install the profile
    mac_profiles_handler::manage { 'com.grahamgilbert.munkiprefs':
        ensure      => present,
        file_source => '/var/lib/puppet/mac_admin/com.grahamgilbert.munkiprefs.mobileconfig',
        require     => File['/var/lib/puppet/mac_admin/com.grahamgilbert.munkiprefs.mobileconfig']
    }

    ##If we need to, touch the bootstrap file
    if ($bootstrap==true){
        exec {'munki-check':
            command     => '/usr/bin/touch /Users/Shared/.com.googlecode.munki.checkandinstallatstartup',
            refreshonly => true,
            subscribe   => Package['munki_tools'],
        }
    }

    class { 'mac_admin::munki::conditions':
      require => Package['munki_tools']
    }
}
