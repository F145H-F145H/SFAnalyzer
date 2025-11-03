<?
/* vi: set sw=4 ts=4: ---------------------------------------------------------*/
$MY_NAME		="st_route";
$MY_MSG_FILE	=$MY_NAME.".php";
$CATEGORY		="st";
/* --------------------------------------------------------------------------- */

/* --------------------------------------------------------------------------- */
$OTHER_META="<meta http-equiv=Refresh content='10;url=st_route.php'>";
require("/www/model/__html_head.php");
?>
<body <?=$G_BODY_ATTR?>>
<form name="frm" id="frm">
<input type="hidden" name="ACTION_POST" value="SOMETHING">
<?require("/www/model/__banner.php");?>
<?require("/www/model/__menu_top.php");?>
<table <?=$G_MAIN_TABLE_ATTR?> height="100%">
<tr valign=top>
	<td <?=$G_MENU_TABLE_ATTR?>>
	<?require("/www/model/__menu_left.php");?>
	</td>
	<td id="maincontent">
		<div id="box_header">
		<?require($LOCALE_PATH."/dsc/dsc_".$MY_NAME.".php");?>
		</div>
<!-- ________________________________ Main Content Start ______________________________ -->
		<div class="box">
			<h2><?=$m_context_title_wlan?></h2>
			<table borderColor=#ffffff cellSpacing=1 cellPadding=2 width=525 bgColor=#dfdfdf border=1>
			<tr id="box_header">
				<td class=bc_tb><?=$m_dstip?></td>
				<td class=bc_tb><?=$m_netmask?></td>
				<td class=bc_tb><?=$m_gateway?></td>
				<td class=bc_tb><?=$m_metric?></td>
				<td class=bc_tb><?=$m_interface?></td>
				<td class=bc_tb><?=$m_type?></td>
				<td class=bc_tb><?=$m_creator?></td>
			</tr>
			<?
			for("/runtime/wan/inf:1/classlessstaticroute")
			{
				echo "<td class=l_tb>".query("dest")."</td>\n";
				echo "<td class=l_tb>".query("subnet")."</td>\n";
				echo "<td class=l_tb>".query("router")."</td>\n";

				echo "<td class=c_tb>0</td>\n";
				echo "<td class=c_tb>".$m_internet."</td>\n";
				echo "<td class=c_tb>".$m_dhcpopt."</td>\n";
				echo "<td class=c_tb>".$m_system."</td></tr>\n";

			}
			for("/runtime/wan/inf:2/classlessstaticroute")
			{
				echo "<td class=l_tb>".query("dest")."</td>\n";
				echo "<td class=l_tb>".query("subnet")."</td>\n";
				echo "<td class=l_tb>".query("router")."</td>\n";

				echo "<td class=c_tb>0</td>\n";
				echo "<td class=c_tb>".$m_internet."</td>\n";
				echo "<td class=c_tb>".$m_dhcpopt."</td>\n";
				echo "<td class=c_tb>".$m_system."</td></tr>\n";

			}

			for("/runtime/wan/inf:1/staticroute")
			{
				echo "<td class=l_tb>".query("dest")."</td>\n";
				echo "<td class=l_tb>".query("subnet")."</td>\n";
				echo "<td class=l_tb>".query("router")."</td>\n";

				echo "<td class=c_tb>0</td>\n";
				echo "<td class=c_tb>".$m_internet."</td>\n";
				echo "<td class=c_tb>".$m_dhcpopt."</td>\n";
				echo "<td class=c_tb>".$m_system."</td></tr>\n";

			}
			for("/runtime/wan/inf:2/staticroute")
			{
				echo "<td class=l_tb>".query("dest")."</td>\n";
				echo "<td class=l_tb>".query("subnet")."</td>\n";
				echo "<td class=l_tb>".query("router")."</td>\n";

				echo "<td class=c_tb>0</td>\n";
				echo "<td class=c_tb>".$m_internet."</td>\n";
				echo "<td class=c_tb>".$m_dhcpopt."</td>\n";
				echo "<td class=c_tb>".$m_system."</td></tr>\n";

			}

			for("/routing/route/entry")
			{
				$inf = query("interface");
				if ($inf == "WAN")			{ $dev = query("/runtime/wan/inf:1/interface"); }
				else if ($inf == "WANPHY")	{ $dev = query("/runtime/wan/inf:2/interface"); }

				if (query("enable")==1 && $dev!="")
				{
					echo "<td class=l_tb>".query("destination")."</td>\n";
					echo "<td class=l_tb>".query("netmask")."</td>\n";
					echo "<td class=l_tb>".query("gateway")."</td>\n";

					echo "<td class=c_tb>0</td>\n";
					echo "<td class=c_tb>".$m_internet."</td>\n";
					echo "<td class=c_tb>".$m_static."</td>\n";
					echo "<td class=c_tb>".$m_admin."</td></tr>\n";
				}
			}
			$wanmode=query("/wan/rg/inf:1/mode");
			if($wanmode == 4 && query("/wan/rg/inf:1/pptp/physical")==1)
			{
				if(query("/runtime/wan/inf:1/connectstatus")=="connected")
				{
					$defroute=query("/runtime/wan/inf:1/gateway");
					if($defroute != "")
					{	
						echo "<td class=l_tb>0.0.0.0</td>\n";
						echo "<td class=l_tb>0.0.0.0</td>\n";
						echo "<td class=l_tb>".$defroute."</td>\n";
						echo "<td class=c_tb>0</td>\n";
						echo "<td class=c_tb>".$m_internet."</td>\n";
						echo "<td class=c_tb>".$m_dhcpopt."</td>\n";
						echo "<td class=c_tb>".$m_system."</td></tr>\n";
					}
				}	
				else
				{
					$defroute=query("/runtime/wan/inf:2/gateway");
					if($defroute != "")
					{
						echo "<td class=l_tb>0.0.0.0</td>\n";
						echo "<td class=l_tb>0.0.0.0</td>\n";
						echo "<td class=l_tb>".$defroute."</td>\n";
						echo "<td class=c_tb>0</td>\n";
						echo "<td class=c_tb>".$m_internet."</td>\n";
						if(query("/wan/rg/inf:1/pptp/mode")==1)
						{
							echo "<td class=c_tb>".$m_static."</td>\n";
							echo "<td class=c_tb>".$m_admin."</td></tr>\n";
						}
						else		
						{
							echo "<td class=c_tb>".$m_dhcpopt."</td>\n";
							echo "<td class=c_tb>".$m_system."</td></tr>\n";
						}
					}
				}
			}
			else
			{
				$defroute=query("/runtime/wan/inf:1/gateway");
				if($defroute != "")
				{	
					echo "<td class=l_tb>0.0.0.0</td>\n";
					echo "<td class=l_tb>0.0.0.0</td>\n";
					echo "<td class=l_tb>".$defroute."</td>\n";
				
					echo "<td class=c_tb>0</td>\n";
					echo "<td class=c_tb>".$m_internet."</td>\n";
					if($wanmode==1)
					{
						echo "<td class=c_tb>".$m_static."</td>\n";
						echo "<td class=c_tb>".$m_admin."</td></tr>\n";
					}
					else
					{
						echo "<td class=c_tb>".$m_dhcpopt."</td>\n";
						echo "<td class=c_tb>".$m_system."</td></tr>\n";
					}
				}
			}
			?>
			</table>
		</div>

<!-- ________________________________  Main Content End _______________________________ -->
	</td>
	<td <?=$G_HELP_TABLE_ATTR?>><?require($LOCALE_PATH."/help/h_".$MY_NAME.".php");?></td>
</tr>
</table>
<?require("/www/model/__tailer.php");?>
</form>
</body>
</html>
