# /bin/sh

# Brew
BREW_LOCATION="/usr/local/bin/brew"
if [ -f $BREW_LOCATION ];
    then
        echo "Brew update"
        brew update
    else
        echo "Installing Brew..."
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# swiftgen
SWIFTGEN_LOCATION="/usr/local/bin/swiftgen"
if [ ! -f $SWIFTGEN_LOCATION ];
    then
        echo "Installing swiftgen..."
        brew install swiftgen
fi

# carthage
CARTHAGE_LOCATION="/usr/local/bin/carthage"
if [ ! -f $CARTHAGE_LOCATION ];
    then
        echo "Installing carthage..."
        brew install carthage
fi

