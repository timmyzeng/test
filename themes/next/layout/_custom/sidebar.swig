<div id="days"></div>
</script>
<script language="javascript">
function show_date_time(){
window.setTimeout("show_date_time()", 1000);
BirthDay=new Date("01/25/2018 18:00:00");
today=new Date();
timeold=(today.getTime()-BirthDay.getTime());
sectimeold=timeold/1000
secondsold=Math.floor(sectimeold);
msPerDay=24*60*60*1000
e_daysold=timeold/msPerDay
daysold=Math.floor(e_daysold);
e_hrsold=(e_daysold-daysold)*24;
hrsold=setzero(Math.floor(e_hrsold));
e_minsold=(e_hrsold-hrsold)*60;
minsold=setzero(Math.floor((e_hrsold-hrsold)*60));
seconds=setzero(Math.floor((e_minsold-minsold)*60));
document.getElementById('days').innerHTML="已运行"+daysold+"天"+hrsold+"小时";
}
function setzero(i){
if (i<10)
{i="0" + i};
return i;
}
show_date_time();
</script>
<div id="music163player">
<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=22712173&auto=1&height=66">
</iframe>
</div>