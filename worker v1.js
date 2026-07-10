export default {

async fetch(request, env){

const url = new URL(request.url);

if(
request.method==="POST" &&
url.pathname==="/report"
){


if(!validateClient(request,env)){

return json({
success:false,
error:"Unauthorized"
},401);

}



let body;

try{

body=await request.json();

}catch{

return json({
success:false,
error:"Invalid JSON"
},400);

}



if(
typeof body.userid !== "number" ||
typeof body.username !== "string"
){

return json({
success:false,
error:"Invalid Payload"
},400);

}



const now =
new Date().toISOString();


// update user aktif

const execution = await supabase(
env,
"POST",
"executions?on_conflict=userid",
{

userid:body.userid,

username:body.username,

displayname:
body.displayname || "",


executor:
body.executor || "Unknown",


version:
body.version || "Unknown",


placeid:
body.placeid || 0,


gamename:
body.gamename || "",


jobid:
body.jobid || "",


device:
body.device || "",


country:
body.country || "",


heartbeat:1,


last_seen:now

}

);



if(!execution.ok){

return json({
success:false,
error:"Database Error",
detail:execution.data
},500);

}



// simpan history

await supabase(
env,
"POST",
"execution_logs",
{

userid:body.userid,

username:body.username,

executor:
body.executor || "Unknown",

version:
body.version || "Unknown",

placeid:
body.placeid || 0,

gamename:
body.gamename || "",

jobid:
body.jobid || ""

}

);



return json({

success:true,

message:"Execution recorded"

});


}

if(request.method==="OPTIONS"){

return new Response(null,{
headers:corsHeaders()
});

}



if(url.pathname==="/"){

return json({

success:true,

api:"Dvisual API",

status:"online",

version:"1.0.0",

time:new Date().toISOString()

});

}

// ============================
// ROUTE: HEARTBEAT
// ============================

if(
request.method==="POST" &&
url.pathname==="/heartbeat"
){


if(!validateClient(request,env)){

return json({
success:false,
error:"Unauthorized"
},401);

}



let body;

try{

body=await request.json();

}catch{

return json({
success:false,
error:"Invalid JSON"
},400);

}



if(typeof body.userid !== "number"){

return json({
success:false,
error:"Invalid UserId"
},400);

}



// ambil heartbeat lama

const getUser = await supabase(
env,
"GET",
`executions?userid=eq.${body.userid}&select=heartbeat`
);



if(!getUser.ok){

return json({
success:false,
error:getUser.data
},500);

}



let heartbeat = 1;


try{

const rows =
JSON.parse(getUser.data);


if(rows.length > 0){

heartbeat =
(rows[0].heartbeat || 0) + 1;

}


}catch{}



// update

const update = await supabase(
env,
"PATCH",
`executions?userid=eq.${body.userid}`,
{

heartbeat:heartbeat,

last_seen:
new Date().toISOString()

}

);



if(!update.ok){

return json({
success:false,
error:update.data
},500);

}



return json({

success:true,

heartbeat:heartbeat

});


}

// ============================
// ROUTE: VERSION
// ============================

if(
request.method==="GET" &&
url.pathname==="/version"
){


const result = await supabase(
env,
"GET",
"system_config?select=config_key,config_value"
);



if(!result.ok){

return json({
success:false,
error:result.data
},500);

}



let config={};


try{

const rows =
JSON.parse(result.data);


rows.forEach(item=>{

config[item.config_key]=item.config_value;

});


}catch{}



return json({

success:true,

version:
config.latest_version || "1.0.0",

maintenance:
config.maintenance || "false",

minimum:
config.minimum_version || "1.0.0"

});


}

// ============================
// ROUTE: ONLINE
// ============================

if(
request.method==="GET" &&
url.pathname==="/online"
){


if(!validateAdmin(request,env)){

return json({
success:false,
error:"Unauthorized"
},401);

}



const since =
new Date(
Date.now() - 60000
).toISOString();



const result = await supabase(
env,
"GET",
`executions?last_seen=gte.${encodeURIComponent(since)}&select=userid,username,gamename,executor,last_seen&order=last_seen.desc`
);



if(!result.ok){

return json({
success:false,
error:result.data
},500);

}



let users=[];


try{

users =
JSON.parse(result.data);

}catch{}



return json({

success:true,

online:users.length,

users:users

});


}

// ============================
// ROUTE: STATS
// ============================

if(
request.method==="GET" &&
url.pathname==="/stats"
){


if(!validateAdmin(request,env)){

return json({
success:false,
error:"Unauthorized"
},401);

}


// ============================
// TOTAL USER
// ============================

const totalUsers = await supabase(
env,
"GET",
"executions?select=id"
);



if(!totalUsers.ok){

return json({
success:false,
error:totalUsers.data
},500);

}



let total_users = 0;


try{

total_users =
JSON.parse(totalUsers.data).length;

}catch{}



// ============================
// ONLINE USER
// ============================

const since =
new Date(
Date.now()-60000
).toISOString();



const onlineUsers = await supabase(
env,
"GET",
`executions?last_seen=gte.${encodeURIComponent(since)}&select=id`
);



let online_now = 0;


try{

online_now =
JSON.parse(onlineUsers.data).length;

}catch{}



// ============================
// TODAY EXECUTION
// ============================

const today =
new Date();

today.setUTCHours(0,0,0,0);


const todayExecute = await supabase(
env,
"GET",
`execution_logs?created_at=gte.${today.toISOString()}&select=id`
);



let today_execute = 0;


try{

today_execute =
JSON.parse(todayExecute.data).length;

}catch{}



// ============================
// TOP GAME
// ============================

const games = await supabase(
env,
"GET",
"execution_logs?select=gamename"
);



let top_games=[];


try{


const rows =
JSON.parse(games.data);


const counter={};


rows.forEach(x=>{

if(!x.gamename) return;


counter[x.gamename] =
(counter[x.gamename]||0)+1;


});


top_games =
Object.entries(counter)
.sort((a,b)=>b[1]-a[1])
.slice(0,5)
.map(x=>({

game:x[0],
count:x[1]

}));



}catch{}



return json({

success:true,

stats:{

total_users,

today_execute,

online_now,

top_games

}

});


}

// ============================
// ROUTE LICENSE CHECK
// ============================

if(
request.method==="POST" &&
url.pathname==="/license/check"
){


if(!validateClient(request,env)){

return json({

success:false,

error:"Unauthorized"

},401);

}



let body;


try{

body =
await request.json();

}catch{

return json({

success:false,

error:"Invalid JSON"

},400);

}



if(
typeof body.userid !== "number"
){

return json({

success:false,

error:"Invalid UserId"

},400);

}



// ======================
// CHECK OWNER
// ======================

const owner =
await supabase(
env,
"GET",
`owners?userid=eq.${body.userid}`
);



let ownerRows=[];


try{

ownerRows =
JSON.parse(owner.data);

}catch{}



if(ownerRows.length){

return json({

success:true,

type:"owner",

message:"Permanent Access"

});

}



// ======================
// CHECK LICENSE
// ======================


if(!body.key){

return json({

success:false,

error:"Missing Key"

});

}



const result =
await supabase(
env,
"GET",
`licenses?license_key=eq.${body.key}&status=eq.active`
);



let rows=[];


try{

rows =
JSON.parse(result.data);

}catch{}



if(rows.length===0){

return json({

success:false,

error:"Invalid Key"

});

}



const license =
rows[0];

// ======================
// LICENSE BINDING
// ======================


if(
license.bound_userid &&
license.bound_userid !== body.userid
){

return json({

success:false,

error:"License Already Bound"

});

}



// first use binding

if(
!license.bound_userid
){

const bind =
await supabase(
env,
"PATCH",
`licenses?id=eq.${license.id}`,
{

bound_userid:
body.userid,


bound_at:
new Date().toISOString()

}

);


if(!bind.ok){

return json({

success:false,

error:"Binding Failed"

},500);

}


}


if(
license.expire_at &&
new Date(license.expire_at)
<
new Date()
){

return json({

success:false,

error:"Expired"

});

}



return json({

success:true,

type:"member",

expire:
license.expire_at

});


}

// ============================
// ROUTE LICENSE GENERATE
// ============================

if(
request.method==="POST" &&
url.pathname==="/license/generate"
){


if(!validateDiscord(request,env)){

return json({

success:false,

error:"Unauthorized"

},401);

}



let body;


try{

body =
await request.json();

}catch{

return json({

success:false,

error:"Invalid JSON"

},400);

}

const days = 1;

const key =
"DV-" +
Math.random()
.toString(36)
.substring(2,8)
.toUpperCase()
+
"-"+
Math.random()
.toString(36)
.substring(2,8)
.toUpperCase();



const expire =
new Date();


expire.setDate(
expire.getDate()+days
);



const result =
await supabase(
env,
"POST",
"licenses",
{

license_key:key,

discord_id:
body.discord_id || "",


discord_name:
body.discord_name || "",


expire_at:
expire.toISOString(),

status:"active"

}

);



if(!result.ok){

return json({

success:false,

error:result.data

},500);

}



return json({

success:true,

key:key,

days:days,

expire:expire.toISOString()

});


}

// ============================
// ROUTE LICENSE RESET
// ============================

if(
request.method==="POST" &&
url.pathname==="/license/reset"
){


if(!validateAdmin(request,env)){

return json({

success:false,

error:"Unauthorized"

},401);

}



let body;


try{

body =
await request.json();

}catch{


return json({

success:false,

error:"Invalid JSON"

},400);


}



if(!body.key){

return json({

success:false,

error:"Missing License Key"

});

}



// reset binding

const result =
await supabase(
env,
"PATCH",
`licenses?license_key=eq.${body.key}`,
{

bound_userid:null,

bound_at:null

}

);



if(!result.ok){

return json({

success:false,

error:result.data

},500);

}



return json({

success:true,

message:"License Binding Reset"

});


}

// ============================
// ROUTE GET KEY
// ============================

if(
request.method==="POST" &&
url.pathname==="/license/getkey"
){


if(!validateDiscord(request,env)){

return json({

success:false,

error:"Unauthorized"

},401);

}



let body;


try{

body =
await request.json();


}catch{


return json({

success:false,

error:"Invalid JSON"

},400);


}



if(!body.discord_id){

return json({

success:false,

error:"Missing Discord ID"

});

}



// cari key terakhir user

const existing =
await supabase(
env,
"GET",
`licenses?discord_id=eq.${body.discord_id}&order=created_at.desc&limit=1`
);



let licenses=[];


try{

licenses =
JSON.parse(existing.data);


}catch{}




// ========================
// CEK KEY AKTIF
// ========================


if(licenses.length){


const old =
licenses[0];



if(
old.status==="active" &&
new Date(old.expire_at)
>
new Date()
){


return json({

success:true,

type:"existing",

key:
old.license_key,

expire:
old.expire_at

});


}


}



// ========================
// BUAT KEY BARU 1 HARI
// ========================


const key =
"DV-" +
Math.random()
.toString(36)
.substring(2,8)
.toUpperCase()
+
"-"+
Math.random()
.toString(36)
.substring(2,8)
.toUpperCase();



const expire =
new Date();


expire.setDate(
expire.getDate()+1
);



const insert =
await supabase(
env,
"POST",
"licenses",
{

license_key:key,

discord_id:
body.discord_id,


discord_name:
body.discord_name || "",


expire_at:
expire.toISOString(),

status:"active"

}

);



if(!insert.ok){

return json({

success:false,

error:insert.data

},500);

}



return json({

success:true,

type:"new",

key:key,

expire:
expire.toISOString()

});


}
  
return json({
success:false,
error:"Not Found"
},404);



}

};



function json(data,status=200){

return new Response(

JSON.stringify(data,null,2),

{

status,

headers:{
...corsHeaders(),
"Content-Type":"application/json"
}

}

);

}



function corsHeaders(){

return {

"Access-Control-Allow-Origin":"*",

"Access-Control-Allow-Headers":
"Content-Type, X-API-Key, X-Admin-Key, X-Discord-Key",  

"Access-Control-Allow-Methods":
"GET, POST, OPTIONS"

};

}

async function supabase(
  env,
  method,
  path,
  body=null
){

const baseUrl = env.SUPABASE_URL.replace(/\/+$/, "");

const res = await fetch(
`${baseUrl}/rest/v1/${path}`, 
{
method,

headers:{
"apikey":env.SUPABASE_SERVICE_KEY,

"Authorization":
`Bearer ${env.SUPABASE_SERVICE_KEY}`,

"Content-Type":
"application/json",

"Prefer":
"resolution=merge-duplicates,return=representation"
},

body:
body
?
JSON.stringify(body)
:
undefined

});

return {
ok:res.ok,
status:res.status,
data:await res.text()
};

}

function validateClient(request,env){

const token =
request.headers.get("X-API-Key");

return token &&
token===env.API_TOKEN;

}

function validateAdmin(request,env){

const token =
request.headers.get("X-Admin-Key");

return token &&
token===env.ADMIN_TOKEN;

}


function validateDiscord(request,env){

const token =
request.headers.get("X-Discord-Key");


return token &&
token===env.DISCORD_SECRET;

} 
