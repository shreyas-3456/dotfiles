# Check if the timezone is already set to Asia/Colombo
if [ "$(cat /etc/timezone)" != "Asia/Colombo" ]; then
    echo "Setting timezone to Asia/Colombo..."

    # 1. Pre-set the answers for the interactive prompt
    echo "tzdata tzdata/Areas select Asia" | sudo debconf-set-selections
    echo "tzdata tzdata/Zones/Asia select Colombo" | sudo debconf-set-selections

    # 2. Run reconfigure non-interactively
    # This uses the answers provided above
    sudo DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive tzdata
    
    echo "Timezone updated successfully." 
fi