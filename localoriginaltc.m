run('pre.m')
folder_name = 'localoriginaltc';

energyfile_name = {
'www.cisco.com'
'www.indianexpress.com'
'www.msn.com'
'www.zdnet.com'
'www.apple.com'
'www.collegehumor.com'
'www.imdb.com'
'www.irs.gov'
'www.kbb.com'
'www.vox.com'
};

% %====Start time
start = [
1591.737444
1675.155549
1757.866335
1841.068956
1882.545747
1967.282243
2009.090958
2050.638963
2103.708131
2176.829667
];

diff = 45.642;

test_webno = 8;


shift = 270.32;
run('prev_analysis.m');
run('post_analysis.m');
