%====Load resource file
time_name=strcat('energy/',folder_name,'/time.txt');
cpu_name=strcat('energy/',folder_name,'/cpu.txt');
network_name=strcat('energy/',folder_name,'/network.txt');
freq_name=strcat('energy/',folder_name,'/frequency.txt');

time=dlmread(time_name,' ')-shift;
cpu=dlmread(cpu_name,' ');
network=dlmread(network_name,' ');
network=network(:,any(network));                               
freq=dlmread(freq_name,' ');


%====Figure out the cpu/net/freq data point of each segment
for webno=1:websites_no
    for k=1:energysize(webno)
        seg_start=start(webno)+D_time_s{webno}(k)/1000;
        seg_end=start(webno)+D_time_e{webno}(k)/1000;
        if seg_start ~= seg_end
            for row_s=1:size(time)
               if time(row_s,1)>=seg_start
                   if abs(time(row_s,1)-seg_start)<abs(time(row_s-1,1)-seg_start)
                       res_start(webno,k)=row_s;
                       break;
                   else
                       res_start(webno,k)=row_s-1;
                       break;
                   end
               end
            end
            for row_e=1:size(time)
               if time(row_e,1)>=seg_end
                   if abs(time(row_e,1)-seg_end)<abs(time(row_e-1,1)-seg_end)
                       if row_e>row_s
                           res_end(webno,k)=row_e;
                           break;
                       else
                           res_end(webno,k)=row_e+1;
                           break;
                       end
                   else
                       if row_e-1>row_s
                           res_end(webno,k)=row_e-1;
                           break;
                       else
                           res_end(webno,k)=row_e;
                           break;
                       end
                   end
               end
           end
        end
    end
end
disp('Resource matching complete.');

%For each segment, calculate cpu%/average freq of each core
for webno=1:websites_no
    for k=1:energysize(webno)
        if D_time_s{webno}(k)~=D_time_e{webno}(k)
            cpu_util{webno,k}=zeros(1,4);
            for core=1:4
                cpu_util{webno,k}(core)=sum(cpu(res_end(webno,k)*4+core-4,[1 2 3 6 7])-cpu(res_start(webno,k)*4+core-4,[1 2 3 6 7]))/100/(time(res_end(webno,k),1)-time(res_start(webno,k),1));
            end
            cpu_freq{webno,k}=zeros(1,4);
            for i=res_start(webno,k):res_end(webno,k)-1
                cpu_freq{webno,k}=cpu_freq{webno,k}+freq(i,[1 2 3 4])*(time(i+1)-time(i));
            end
            cpu_freq{webno,k}=cpu_freq{webno,k}/(time(res_end(webno,k),1)-time(res_start(webno,k),1));
            net_util{webno,k}=(network(res_end(webno,k),[1])-network(res_start(webno,k),[1]))/(time(res_end(webno,k),1)-time(res_start(webno,k),1));
        end
    end
end
disp('Resource computation complete.');

% figure;
% for plotnum=1:4
%     plot(1:size(cpu_util{test_webno,:},1),cpu_util{test_webno,:}(i))
% end
% coeff=load('4CV_Mobipower_new.mat','coeffs3');
% coeff=coeff.coeffs3;

% coeff=load('new_coeff.mat','coeff');
% coeff=coeff.coeff;


coeff=load('newcoeff.mat','coeff');
coeff=coeff.coeff;

%====Target 'timeslot'====
cpu_start_flag=0;
cpu_end_flag=0;
cpu_avg_freq=zeros(1,4);
count=0;
for i=1:size(time,1)
    %cpu_util & network
    if (time(i)>start(test_webno)+timeslot(1)) && ~cpu_start_flag
        time_start=time(i);
        cpu0_start=cpu(i*4-3,[1 2 3 6 7]);
        cpu1_start=cpu(i*4-2,[1 2 3 6 7]);
        cpu2_start=cpu(i*4-1,[1 2 3 6 7]);
        cpu3_start=cpu(i*4,[1 2 3 6 7]);
        network_start=network(i,:);
        cpu_start_flag=1;
    end
    if (time(i)>start(test_webno)+timeslot(2)) && ~cpu_end_flag
        time_end=time(i);
        cpu0_end=cpu(i*4-3,[1 2 3 6 7]);
        cpu1_end=cpu(i*4-2,[1 2 3 6 7]);
        cpu2_end=cpu(i*4-1,[1 2 3 6 7]);
        cpu3_end=cpu(i*4,[1 2 3 6 7]);
        network_end=network(i,:);
        cpu_end_flag=1;
    end
    %cpu_freq
    if (time(i)>start(test_webno)+timeslot(1)) && (time(i)<start(test_webno)+timeslot(2))
        count=count+1;
        cpu_avg_freq=cpu_avg_freq+freq(i);
    end    
end
cpu0_avg_util=(sum(cpu0_end)-sum(cpu0_start))/100/(time_end-time_start);
cpu1_avg_util=(sum(cpu1_end)-sum(cpu1_start))/100/(time_end-time_start);
cpu2_avg_util=(sum(cpu2_end)-sum(cpu2_start))/100/(time_end-time_start);
cpu3_avg_util=(sum(cpu3_end)-sum(cpu3_start))/100/(time_end-time_start);
cpu_avg_util=[cpu0_avg_util cpu1_avg_util cpu2_avg_util cpu3_avg_util];
cpu_avg_freq=cpu_avg_freq/count;
cpu_avg_util_freq=cpu_avg_util.*cpu_avg_freq;
network_avg=(network_end([1])-network_start([1]))/(time_end-time_start);

disp('----------')
disp(folder_name)
disp(energyfile_names{test_webno})
disp(['time_period: ',num2str(timeslot)]);
disp(['cpu_avg_util: ',num2str(cpu_avg_util)]);
% disp(['cpu_util_coeff: ',num2str(coeff(6:9)')]);
% disp(['time_period: ',num2str(timeslot)]);
% disp(['cpu_util_energy: ',num2str(cpu_avg_util.*coeff(6:9)'*(timeslot(2)-timeslot(1)))]);
temp1=sum(cpu_avg_util.*coeff(6:9)'*(timeslot(2)-timeslot(1)));
% disp(['total_cpu_util_energy: ',num2str(temp1)])

% disp('--------')
disp(['cpu_avg_freq: ',num2str(cpu_avg_freq)]);
% disp(['cpu_freq_coeff: ',num2str(coeff(10:13)')]);
% disp(['time_period: ',num2str(timeslot)]);
% disp(['cpu_freq_energy: ',num2str(cpu_avg_freq.*coeff(10:13)'*(timeslot(2)-timeslot(1)))]);
temp2=sum(cpu_avg_freq.*coeff(10:13)'*(timeslot(2)-timeslot(1)));
% disp(['total_cpu_freq_energy: ',num2str(temp2)])

% disp('--------')
% disp(['cpu_avg_util_freq: ',num2str(cpu_avg_util_freq)]);
% disp(['cpu_util_freq_coeff: ',num2str(coeff(14:17)')]);
% disp(['time_period: ',num2str(timeslot)]);
% disp(['cpu_util_freq_energy: ',num2str(cpu_avg_util_freq.*coeff(14:17)'*(timeslot(2)-timeslot(1)))]);
temp3=sum(cpu_avg_util_freq.*coeff(14:17)'*(timeslot(2)-timeslot(1)));
% disp(['total_cpu_util_freq_energy: ',num2str(temp3)])

% disp('--------')
total_cpu_energy=temp1+temp2+temp3;
% disp(['total_cpu_energy: ',num2str(total_cpu_energy)]);

% disp('--------')
disp(['network: ',num2str(network_avg)]);
% disp(['network_coeff: ',num2str(coeff(18)')]);
% disp(['time_period: ',num2str(timeslot)]);
% disp(['network_energy: ',num2str(network_avg.*coeff(18)'*(timeslot(2)-timeslot(1)))]);
total_network_energy=sum(network_avg.*coeff(18)'*(timeslot(2)-timeslot(1)));
% disp(['total_network_energy: ',num2str(total_network_energy)])

disp(' ')
% c('application/font-woff2')=3;
% c('text/xml')=11;
% c('application/vnd.sun.wadl+xml')=5;
% c('application/vnd.api+json')=1;




c = containers.Map;


c('1') = 1;
c('2') = 1;
c('3') = 1;                                                                                                                                                                              
c('4') = 2;
c('evalhtml') = 3;
download_col=4;

js_len=zeros(websites_no,1);
css_len=zeros(websites_no,1);
html_len=zeros(websites_no,1);
download_len=zeros(websites_no,1);

X1=[];
segments=[];
cpu_energy_decompression=0;
time_decompression=0;
% disp('Setting Up WProf Matrix...')
for webno=1:websites_no
    
    segments(end+1)=0;
    components=D_components{webno};
    for k=1:energysize(webno)
        if abs(D_time_s{webno}(k)-D_time_e{webno}(k))>threshold
            flag=0;
            segments(end)=segments(end)+1;
            X1(end+1,:)=zeros(1,download_col);
            temp=num2str(cell2mat(components(k)));
            test_content=strsplit(temp);
            for n=1:size(test_content,2)
                if(strcmp('of',test_content{n})==1)
                    id=test_content{n+1};
                    if ~isKey(c,id)
                        if (strcmp(id,'application/javascript') || strcmp(id,'text/html') || strcmp(id,'text/css')) && test_webno==webno && flag==0
                            flag=1;
                            time_decompression=time_decompression+abs(D_time_s{webno}(k)-D_time_e{webno}(k))/1000;
                            cpu_energy_decompression=cpu_energy_decompression+sum(coeff(6:17)'.*[cpu_util{webno,k} cpu_freq{webno,k} cpu_util{webno,k}.*cpu_freq{webno,k}])*abs(D_time_s{webno}(k)-D_time_e{webno}(k))/1000;
                        end
                        X1(end,download_col)=X1(end,download_col)+1;
                        download_len(webno)=download_len(webno)+abs(D_time_s{webno}(k)-D_time_e{webno}(k))/1000;
                    else
                        X1(end,c(id))=X1(end,c(id))+1;
                        if strcmp(id,'1') || strcmp(id,'2') || strcmp(id,'3')
                            js_len(webno)=js_len(webno)+abs(D_time_s{webno}(k)-D_time_e{webno}(k))/1000;
                        elseif strcmp(id,'4')
                            css_len(webno)=css_len(webno)+abs(D_time_s{webno}(k)-D_time_e{webno}(k))/1000;
                        elseif strcmp(id,'evalhtml')
                            html_len(webno)=html_len(webno)+abs(D_time_s{webno}(k)-D_time_e{webno}(k))/1000;
                        end
                    end
                end
            end            
        end
    end
end

disp('Time_During_Compression                  CPU_Energy_Decompression')
disp([num2str(time_decompression),'                                          ', num2str(cpu_energy_decompression)])

X2=[];
X3=[];
test_cpu=zeros(websites_no,1);
test_cpu1=zeros(websites_no,1);
test_cpu2=zeros(websites_no,1);
test_cpu3=zeros(websites_no,1);

test_baseline=zeros(websites_no,1);
test_network=zeros(websites_no,1);
% disp('Setting Up Resource Matrix and Record Segment Duration...')
for webno=1:websites_no
    for k=1:energysize(webno)
        if abs(D_time_s{webno}(k)-D_time_e{webno}(k))>threshold
            X2(end+1,:)=[cpu_util{webno,k} cpu_freq{webno,k} cpu_util{webno,k}.*cpu_freq{webno,k} net_util{webno,k}];
            X3(end+1,:)=abs(D_time_s{webno}(k)-D_time_e{webno}(k));
            test_baseline(webno)=test_baseline(webno)+coeff(1)*abs(D_time_s{webno}(k)-D_time_e{webno}(k))/1000;
            test_cpu(webno)=test_cpu(webno)+sum(coeff(6:17)'.*[cpu_util{webno,k} cpu_freq{webno,k} cpu_util{webno,k}.*cpu_freq{webno,k}])*abs(D_time_s{webno}(k)-D_time_e{webno}(k))/1000;
            test_cpu1(webno)=test_cpu1(webno)+sum(coeff(6:9)'.*[cpu_util{webno,k}])*abs(D_time_s{webno}(k)-D_time_e{webno}(k))/1000;
            test_cpu2(webno)=test_cpu2(webno)+sum(coeff(10:13)'.*[cpu_freq{webno,k}])*abs(D_time_s{webno}(k)-D_time_e{webno}(k))/1000;
            test_cpu3(webno)=test_cpu3(webno)+sum(coeff(14:17)'.*[cpu_util{webno,k}.*cpu_freq{webno,k}])*abs(D_time_s{webno}(k)-D_time_e{webno}(k))/1000;            
            test_network(webno)=test_network(webno)+coeff(end)*net_util{webno,k}*abs(D_time_s{webno}(k)-D_time_e{webno}(k))/1000;
        end
    end
end

% figure
%     plot(1:size(list,1),mean_list)
%     hold on;

X=[ones(size(X1,1),1) X1 X2];
Y_hat=X*coeff;

pJoules=[];
count=0;
pJoules_part=0;

for webno=1:websites_no
    pJoules(end+1)=0;
    seg_starttime=0;
    for k=1:energysize(webno)
        seg_endtime=seg_starttime+abs(D_time_s{webno}(k)-D_time_e{webno}(k))/1000;
        if abs(D_time_s{webno}(k)-D_time_e{webno}(k))>threshold
            count=count+1;
            pJoules(end)=pJoules(end)+Y_hat(count)*abs(D_time_s{webno}(k)-D_time_e{webno}(k))/1000;
            if (seg_starttime>=timeslot(1)) && (seg_endtime<=timeslot(2)) && (webno==test_webno)
               pJoules_part=pJoules_part+Y_hat(count)*abs(D_time_s{webno}(k)-D_time_e{webno}(k))/1000;
            end
        end
        seg_starttime=seg_endtime;
    end
end

disp('-----RECON Prediction-----')
disp('  Actual(J) Predicted(J) Error%')
disp([Joules(test_webno) pJoules(test_webno)' abs(pJoules(test_webno)'-Joules(test_webno))/Joules(test_webno)*100])
% disp('-----During Observerd Time-----')
% disp('Actual Joules(J)    Predicted Joules(J)')
% disp([Joules_part pJoules_part])
disp('-----Components Length(s)-------')
disp('      js        css      html    downloads')
disp([js_len(test_webno) css_len(test_webno) html_len(test_webno) download_len(test_webno)])
disp('-----Energy Decomposition-------')
disp('    baseline    js       css       html    downloads    cpu    network')

% disp([PLT(test_webno)*coeff(1) js_len(test_webno)*coeff(2) css_len(test_webno)*coeff(3) html_len(test_webno)*coeff(4) download_len(test_webno)*coeff(5) total_cpu_energy total_network_energy]);
disp([PLT(test_webno)*coeff(1) js_len(test_webno)*coeff(2) css_len(test_webno)*coeff(3) html_len(test_webno)*coeff(4) download_len(test_webno)*coeff(5) test_cpu(test_webno) test_network(test_webno)]);
disp('-----CPU Energy Decomposition')
disp('cpu_util       cpu_freq      cpu_util_freq')
disp([test_cpu1(test_webno) test_cpu2(test_webno) test_cpu3(test_webno)])
% disp(PLT*coeff(1)./pJoules')

delete(strcat(folder_name,'.txt'))
fileID=fopen(strcat(folder_name,'.txt'),'w');
fprintf(fileID,'%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n','Webname','PLT','ActualJ','PredictJ','Baseline','JS','CSS','HTML','Downloads','CPU','Network');
for test_webno=1:websites_no
    fprintf(fileID,'%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n',energyfile_names{test_webno},num2str(PLT(test_webno)),num2str(Joules(test_webno)),num2str(pJoules(test_webno)),num2str(PLT(test_webno)*coeff(1)),num2str(js_len(test_webno)*coeff(2)),num2str(css_len(test_webno)*coeff(3)),num2str(html_len(test_webno)*coeff(4)),num2str(download_len(test_webno)*coeff(5)),num2str(test_cpu(test_webno)),num2str(test_network(test_webno)));
end
fclose(fileID);
seg_start=sum(segments(1:test_webno-1))+1;
seg_end=seg_start+segments(test_webno)-1;

% % Calculate real time based on segments
% timestamp(1)=X3(seg_start)/2;
% for i=2:segments(test_webno)
%     timestamp(i)=timestamp(i-1)+(X3(seg_start+i-2)+X3(seg_start+i-1))/2;
% end
% % 
% % figure
% % plot(1:segments(test_webno),Y_hat(seg_start:seg_end));
% % hold on;
% % plot(1:segments(test_webno),power(seg_start:seg_end));
% fixed_time=[0 timestamp timestamp(end)+X3(seg_end)/2]/1000;
% fixed_power=[Y_hat(seg_start) Y_hat(seg_start:seg_end)' Y_hat(seg_end)];
% 
% figure
% plot(powerfile_web{test_webno}(:,1),powerfile_web{test_webno}(:,2));
% hold on;
% % plot(timestamp,Y_hat(seg_start:seg_end))
% stairs(fixed_time,fixed_power,'LineWidth',3)
% ylim([1 6])
% xlabel('Time (s)\rightarrow')
% ylabel('Power (W)\rightarrow')
% close all
% [PLT Joules]
