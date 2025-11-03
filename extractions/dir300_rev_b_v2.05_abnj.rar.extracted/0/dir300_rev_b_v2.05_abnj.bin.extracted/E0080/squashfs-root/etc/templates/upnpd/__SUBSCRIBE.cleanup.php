<?
$curr_time = query("/runtime/sys/uptime");
$count = 0;
for ("subscription") { $count++; }
while ($count > 0)
{
	$timeout = query("subscription:".$count."/timeout");
	if ($timeout > 0 && $timeout < $curr_time)
	{
		del("subscription:".$count);
	}
	$count--;
}
?>
