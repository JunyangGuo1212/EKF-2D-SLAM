% SLAM algorithm

% I. INITIALIZE
%
%   0. System def.

% System noise
q = [0.01;0.01];
Q = diag(q.^2);
% Measurement noise
m = [.15; 1*pi/180];
M = diag(m.^2);
% randn('seed',1);

%
%   1. Simulator
%       R: robot pose u: control
%       W: ��������·���λ��
R = [0;-2.5;0];
u = [0.1;0.05];
% ����landmarks
move_r =6;
r1=4;
r2=8;
W = landmarks1(r1,r2,move_r);

% Id������Ź۲����·����Id�������c++ʵ�֣�����ʹ��map�ṹ��
Id = zeros(1,size(W,2));
y_olds = zeros(3,size(W,2));
y_news = zeros(3,size(W,2));

%   2. Estimator
%   ״̬����Э����
x = zeros(numel(R)+numel(W), 1);
P = zeros(numel(x),numel(x));

mapspace = zeros(1,size(W,2));
r = [1 2 3];
s = [4 5];
x(r) = R;
P(r,r) = 0;

%   3. Graphics
mapFig = figure(1);
cla;
axis([-8 8 -8 8])
axis square
% ����·���
WG = line('parent',gca,...
    'linestyle','none',...
    'marker','.',...
    'color','k',...
    'xdata',W(1,:),...
    'ydata',W(2,:));
% �����»����˳�ʼλ��
RG = line('parent',gca,...
    'marker','.',...
    'color','r',...
    'xdata',R(1),...
    'ydata',R(2));
% ����Ļ����˳�ʼλ��
rG = line('parent',gca,...
    'linestyle','none',...
    'marker','+',...
    'color','b',...
    'xdata',x(r(1)),...
    'ydata',x(r(2)));
% ���Ƶ�·���λ��
lG = line('parent',gca,...
    'linestyle','none',...
    'marker','+',...
    'color','b',...
    'xdata',[],...
    'ydata',[]);

eG1 = zeros(1,size(W,2));
for i = 1:numel(eG1)
    eG1(i) = line(...
        'parent', gca,...
        'color','r',...
        'xdata',[],...
        'ydata',[]);
end

reG = line(...
    'parent', gca,...
    'color','m',...
    'xdata',[],...
    'ydata',[]);

% II. Temporal loop

for t = 1:2310
    
    % 1. Simulator
    n = q.*randn(2,1);
    % ��һʱ�̻�����λ�ã�
    R = move(R, u, n);
    % ��������ȡ����Ϣ��i��ʾ·����ΨһID��ʶ�ţ�yi��ʾ�۲⵽���������ڵ�ǰ����ϵ�����꣬����Ϊ�㣬��ʾ����·���û�й۲⵽��
    % �۲⵽��·�����������Դ��
    % 1:�����۲⵽����EKFʱ��ֻ��Ҫ��������۲ⷽ��project�Ե�ǰ״̬�����������Ϳ����ˡ�
    % 2:֮ǰδ���۲⵽������ʱ����Ҫ��״̬�������㣬������۲ⷽ��backProject��ʼ������״̬��
    % y_olds ��ʾ�����۲⵽����·��㼯�ϡ�
    % y_news ��ʾ�·��ֵĵ�·��㼯�ϡ�
    i_olds=1;
    i_news=1;
    temp =1;
    for i = 1:size(W,2)
        v = m.*randn(2,1);
         yi= project(R, W(:,i)) + v;
        if (yi(2)>0) && (yi(1)>0) && (Id(i)==1)
        %if (Id(i)==1)
               y_olds(:,i_olds) = [yi(1);yi(2);i];
               i_olds = i_olds + 1;
        elseif (Id(i)==0) &&(yi(2)>0) &&(yi(1)>0) && temp <10
                y_news(:,i_news) = [yi(1);yi(2);i];
                i_news = i_news + 1;
                Id(i) = 1;
                temp = temp +1;
        end
    end
    
    for i = i_olds:size(W,2)
        y_olds(:,i) = [100;0;0];
    end
    for i = i_news:size(W,2)
        y_news(:,i) = [101;0;0];
    end
  
    % 2. Filter
    %   a. Prediction
    %   CAUTION this is sub-optimal in CPU time
    % [x(r), R_r, R_n] = move(x(r), u, n);
    % x(r)��һ��Ԥ��λ�ã�R_r��R_n��x(r)��R��n�ڵ�ǰ״̬���ſɱȾ���
    [x(r), R_r, R_n] = move(x(r), u, [0 0]);
    P_rr = P(r,r);
    P(r,:) = R_r*P(r,:);
    P(:,r) = P(r,:)';
    P(r,r) = R_r*P_rr*R_r' + R_n*Q*R_n';
    
 %     b. correction
  %        i. known lmks
         % �۲ⷶΧ����ǰʱ�̻�۲⵽�����������۲����·��㣻
          %�Զ���۲����Ĵ���ʽ���Թ۲����������ÿ�θ��ݶ�һ��·���Ĺ۲�����״̬���и���
    end_old = find(y_olds(1,:)==100,1);  
    if isempty(end_old)
        end_old=size(y_olds,2)+1;
    end
    for j = 1:(end_old-1)
        % expectation
        if isempty(j)
            break
        end
        id = find(mapspace==y_olds(3,j),1);
        v = [id*2+2 id*2+3];
        [e, E_r, E_l] = project(x(r), x(v));
        E_rl = [E_r E_l];
        rl   = [r v];
        E    = E_rl * P(rl,rl) * E_rl';
        
        % measurement
        yi_1 = y_olds(:,j);
        yi1 = yi_1(1:2,1);
        
        % innovation
        z = yi1 - e;
        if z(2) > pi
            z(2) = z(2) - 2*pi;
        end
        if z(2) < -pi
            z(2) = z(2) + 2*pi;
        end
        Z = M + E;
        
        % Kalman gain
        K = P(:, rl) * E_rl' * Z^-1;
        
        % update
        x = x + K * z;
        P = P - K * Z * K';
    end
    
    %ÿ����ѭ�����״̬�������㣬����һ���µ�·���״̬��������ȵ�·���ȫ���Ѿ���ʼ������ô��ʼ�����־Ͳ�����ִ�С�
     %     ii. init new lmks
    end_new = find(y_news(1,:)==101,1);
    if isempty(end_new)
        end_new=size(y_news,2)+1;
    end
    for m1 = 1:(end_new-1)
        if isempty(m1)
            break
        end
        id = find(mapspace==0,1);
        mapspace(id) = y_news(3,m1);
        
        % measurement
        yi_2 = y_news(:,m1);
        yi2 = yi_2(1:2,1);
        [x(s), L_r, L_y] = backProject(x(r ), yi2);
        P(s,:) = L_r * P(r,:);
        P(:,s) = P(s,:)';
        P(s,s) = L_r * P(r,r) * L_r' + L_y * M * L_y';
        s = s + [2 2];
    end
    
     % 3. Graphics
    
    set(RG, 'xdata', R(1), 'ydata', R(2));
    set(rG, 'xdata', x(r(1)), 'ydata', x(r(2)));
    if s(1)<=4
        continue
    end
        w = 2:((s(1)-2)/2);
        w = 2*w;
        lx = x(w);
        ly = x(w+1);
        set(lG, 'xdata', lx, 'ydata', ly);
        
        
  % �������Ƶ�·���λ��
  % ��ǰ���Ƶ�·����Ϊ���֣�
  % 1���ո�̽�����ֵ�
  % 2��֮ǰ����������������������
  % 3��֮ǰ����������ǰû������
  for i = 1:numel(eG1)
    set(eG1(i),'xdata',X,'ydata',Y,'color','w');
  end
  %%%%%��һ�֣��ո�̽�����ֵģ���ɫ��
  for g1 = 1:(end_new-1)
      if isempty(g1)
            break
      end
      o1 = y_news(3,g1);
      h1 = find(mapspace==o1,1);
      %plot1 = ()
      temp1 = [2*h1+2;2*h1+3];
      le = x(temp1);
      LE = P(temp1,temp1);
      [X,Y] = cov2elli(le,LE,3,16);   
      set(eG1(o1),'xdata',X,'ydata',Y,'color','b');
  end
  %%%%�ڶ��֣�֮������������������������
  for g2 = 1:(end_old-1)
      if isempty(g2)
            break
      end
      o2 = y_olds(3,g2);
      h2 = find(mapspace==o2,1);
      temp2 = [2*h2+2;2*h2+3];
      le = x(temp2);
      LE = P(temp2,temp2);
      [X,Y] = cov2elli(le,LE,3,16);  
      set(eG1(o2),'xdata',X,'ydata',Y,'color','r');
  end
  %%%%�����֣�֮ǰ������������û������
  v = find(mapspace==0,1);
  if isempty(v)
      v = size(mapspace,2)+1;
  end
  for g3 = 1:v-1
      if isempty(g3)
            break
      end
      %temp3 = [0;0];
      %a=mapspace(g3);
      a = find(y_olds(3,:)==mapspace(g3),1);
      b = find(y_news(3,:)==mapspace(g3),1);   
      if (isempty (a)) && (isempty(b)) 
         temp3 =  [2*g3+2;2*g3+3];
      
      %h2 = find(mapspace==o2,1);
      %temp2 = [2*h2+2;2*h2+3];
      le = x(temp3);
      LE = P(temp3,temp3);
      [X,Y] = cov2elli(le,LE,3,16);
      set(eG1(mapspace(g3)),'xdata',X,'ydata',Y,'color','k');
      end
  end

     if t > 1
         re = x(r(1:2));
         RE = P(r(1:2),r(1:2));
         [X,Y] = cov2elli(re,RE,3,16);
         set(reG,'xdata',X,'ydata',Y);
     end
    drawnow;
end


