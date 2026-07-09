require("dotenv").config();

const {
    Client,
    GatewayIntentBits,
    REST,
    Routes,
    SlashCommandBuilder,
    EmbedBuilder
} = require("discord.js");


const client = new Client({
    intents:[
        GatewayIntentBits.Guilds
    ]
});


const OWNER_ROLE_ID = "1524786016828002314";
const MEMBER_ROLE_ID = "1524786725057204404";


function isOwner(interaction){

    return interaction.member.roles.cache.has(
        OWNER_ROLE_ID
    );

}

async function sendLog(embed){

    const channel =
    client.channels.cache.get(
        process.env.LOG_CHANNEL_ID
    );


    if(!channel)
        return;


    channel.send({
        embeds:[
            embed
        ]
    });

}


const commands = [

    new SlashCommandBuilder()
    .setName("getkey")
    .setDescription("Ambil license key Dvisual"),


    new SlashCommandBuilder()
    .setName("stats")
    .setDescription("Lihat statistik Dvisual"),


    new SlashCommandBuilder()
    .setName("online")
    .setDescription("Lihat user online Dvisual"),


    new SlashCommandBuilder()
    .setName("resetkey")
    .setDescription("Reset binding license")
    .addStringOption(option =>
        option
        .setName("key")
        .setDescription("License key")
        .setRequired(true)
    )

].map(command => command.toJSON());


const rest = new REST({
    version:"10"
}).setToken(
    process.env.DISCORD_TOKEN
);


async function registerCommands(){

    await rest.put(

        Routes.applicationGuildCommands(
            process.env.DISCORD_CLIENT_ID,
            process.env.DISCORD_GUILD_ID
        ),

        {
            body:commands
        }

    );


    console.log("Command registered");

}


client.once("ready",()=>{

    console.log(
        `Bot online sebagai ${client.user.tag}`
    );

});


client.on("interactionCreate", async interaction => {


    if(!interaction.isChatInputCommand())
        return;


    // ============================
    // COMMAND: GETKEY
    // ============================

    if(interaction.commandName === "getkey"){


        await interaction.deferReply({
            ephemeral:true
        });


        try{


            const response =
            await fetch(
                process.env.API_URL + "/license/getkey",
                {

                    method:"POST",

                    headers:{

                        "Content-Type":"application/json",

                        "X-Discord-Key":
                        process.env.DISCORD_SECRET

                    },

                    body:JSON.stringify({

                        discord_id:
                        interaction.user.id,

                        discord_name:
                        interaction.user.tag

                    })

                }
            );


            const data =
            await response.json();


            if(!data.success){

                return interaction.editReply(
                    "❌ " + data.error
                );

            }


            const embed =
            new EmbedBuilder()

            .setTitle("🔑 Dvisual License")

            .addFields(

                {
                    name:"License Key",
                    value:"`" + data.key + "`"
                },

                {
                    name:"Duration",
                    value:"1 Day"
                },

                {
                    name:"Status",
                    value:"Active"
                }

            )

            .setColor(0x5865F2)

            .setFooter({
                text:"Dvisual License System"
            });


            await interaction.editReply({
                embeds:[embed]
            });


            const logEmbed =
            new EmbedBuilder()

            .setTitle("🔑 New License Generated")

            .addFields(

            {
            name:"User",
            value:interaction.user.tag
            },

            {
            name:"Discord ID",
            value:interaction.user.id
            },

            {
            name:"License",
            value:"`"+data.key+"`"
            },

            {
            name:"Duration",
            value:"1 Day"
            }

            )

            .setColor(0x5865F2);


            sendLog(logEmbed);

            // AUTO ADD MEMBER ROLE

            try{

                const memberRole =
                interaction.guild.roles.cache.get(
                    MEMBER_ROLE_ID
                );


                if(memberRole){

                    await interaction.member.roles.add(
                        memberRole
                    );


                    console.log(
                        "Member role added:",
                        interaction.user.tag
                    );

                }


            }catch(error){

                console.log(
                    "Add Role Error:",
                    error
                );

            }


        }catch(error){


            console.log(error);


            return interaction.editReply(
                "❌ API Error"
            );


        }


    }


    // ============================
    // COMMAND: STATS
    // ============================

    if(interaction.commandName === "stats"){


        if(!isOwner(interaction)){

        return interaction.reply({
        content:"❌ You do not have permission.",
        ephemeral:true
        });

        }


        await interaction.deferReply({
            ephemeral:true
        });


        try{


            const response =
            await fetch(
                process.env.API_URL + "/stats",
                {

                    method:"GET",

                    headers:{

                        "X-Admin-Key":
                        process.env.ADMIN_TOKEN

                    }

                }
            );


            const data =
            await response.json();


            console.log("STATS RESPONSE:", data);


            if(!data.success){

                return interaction.editReply(
                    "❌ " + data.error
                );

            }


            const stats =
            data.stats;


            const topGames =
            stats.top_games && stats.top_games.length > 0
            ?
            stats.top_games
            .map((game,index)=>{
                return `${index+1}. ${game.game} — ${game.count}x`;
            })
            .join("\n")
            :
            "Belum ada data";


            const embed =
            new EmbedBuilder()

            .setTitle("📊 Dvisual Statistics")

            .addFields(

                {
                    name:"Total Users",
                    value:String(stats.total_users || 0),
                    inline:true
                },

                {
                    name:"Online Now",
                    value:String(stats.online_now || 0),
                    inline:true
                },

                {
                    name:"Today Execute",
                    value:String(stats.today_execute || 0),
                    inline:true
                },

                {
                    name:"Top Games",
                    value:topGames,
                    inline:false
                }

            )

            .setColor(0x00ff99);


            return interaction.editReply({
                embeds:[embed]
            });


        }catch(error){


            console.log(error);


            return interaction.editReply(
                "❌ API Error"
            );


        }


    }


    // ============================
    // COMMAND: ONLINE
    // ============================

    if(interaction.commandName === "online"){


        if(!isOwner(interaction)){

            return interaction.reply({
                content:"❌ Tidak memiliki akses.",
                ephemeral:true
            });

        }


        await interaction.deferReply({
            ephemeral:true
        });


        try{


            const response =
            await fetch(
                process.env.API_URL + "/online",
                {

                    method:"GET",

                    headers:{

                        "X-Admin-Key":
                        process.env.ADMIN_TOKEN

                    }

                }
            );


            const data =
            await response.json();


            console.log("ONLINE RESPONSE:", data);


            if(!data.success){

                return interaction.editReply(
                    "❌ " + data.error
                );

            }


            let text = "";


            if(data.users && data.users.length > 0){

                data.users.slice(0,10).forEach((user,index)=>{

                    text +=
                    `${index+1}. ${user.username || "Unknown"} | ${user.gamename || "Unknown Game"} | ${user.executor || "Unknown"}\n`;

                });

            }


            const embed =
            new EmbedBuilder()

            .setTitle("🟢 Dvisual Online")

            .setDescription(
                `Online: ${data.online || 0}\n\n${text || "Tidak ada user online"}`
            )

            .setColor(0x00ff99);


            return interaction.editReply({
                embeds:[embed]
            });


        }catch(error){


            console.log(error);


            return interaction.editReply(
                "❌ API Error"
            );


        }


    }


    // ============================
    // COMMAND: RESET KEY
    // ============================

    if(interaction.commandName === "resetkey"){


        if(!isOwner(interaction)){

            return interaction.reply({
                content:"❌ Tidak memiliki akses.",
                ephemeral:true
            });

        }


        const key =
        interaction.options.getString("key");


        await interaction.deferReply({
            ephemeral:true
        });


        try{


            const response =
            await fetch(
                process.env.API_URL + "/license/reset",
                {

                    method:"POST",

                    headers:{

                        "Content-Type":"application/json",

                        "X-Admin-Key":
                        process.env.ADMIN_TOKEN

                    },

                    body:JSON.stringify({

                        key:key

                    })

                }
            );


            const data =
            await response.json();


            console.log("RESET RESPONSE:", data);


            if(!data.success){

                return interaction.editReply(
                    "❌ " + data.error
                );

            }


            await interaction.editReply(
                "✅ Binding license berhasil direset."
            );


            const logEmbed =
            new EmbedBuilder()

            .setTitle("♻️ License Reset")

            .addFields(

            {
            name:"Admin",
            value:interaction.user.tag
            },

            {
            name:"Discord ID",
            value:interaction.user.id
            },

            {
            name:"License",
            value:"`" + key + "`"
            },

            {
            name:"Action",
            value:"Binding Cleared"
            }

            )

            .setColor(0xff9900)

            .setFooter({
            text:"Dvisual License System"
            });


            sendLog(logEmbed);


        }catch(error){


            console.log(error);


            return interaction.editReply(
                "❌ API Error"
            );


        }


    }


});


registerCommands();


client.login(
    process.env.DISCORD_TOKEN
);