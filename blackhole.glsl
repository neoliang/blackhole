const float Pi = 3.1415926;
vec3 black_hole_pos = vec3(0.0,-0.35,2.0); 		//黑洞的位置
float event_horizon_radius = 0.3;		//黑洞的事件视界半径
float HitTest(vec3 p){
	return length(p) - event_horizon_radius;
}
vec2 N22(vec2 id)
{
    id = id*vec2(123.1,456.2);
    id += dot(id,id);
    return fract(sin(id)*vec2(5.123,123.3));
}
float N21(vec2 id)
{
    id = id*vec2(227.1,125.2);
    return fract(sin(dot(id,id))*215.3);
}
vec2 rPos(vec2 id)
{
    return  N22(id) -.5;
}
vec3 star(vec2 uv,vec2 id)
{
    float l = length(uv);
    //float l = max(abs(uv.x),abs(uv.y));
    float center = 0.035/l;
    float st = center  ;

    float N = N21(id);
    float Size = N*2.;
    vec3 color = sin(vec3(0.2,0.5,0.7)*fract(N*73.1)*15.)*0.5+0.5;
    return st * N * smoothstep(1.,0.,l) * color*vec3(1.0,0.7,Size);
}
vec3 starLayer(vec2 uv,float i)
{
    vec2 id = floor(uv);
    uv = fract(uv)-0.5;

    vec3 col = vec3(0.);
    
    for(float x = -1.;x<=1.;++x){
        for(float y = -1.;y<=1.;++y){
            vec2 nid = id + vec2(x,y);
            vec2 rpos = rPos(nid+i+1.);   
            vec2 nuv = uv + rpos - vec2(x,y);         
            vec3 st = star(nuv,nid);           
            col += st*fract(cos((i+1.)*100.)*23.1)*3.5;
        }
    }

    return col;
}
vec3 GetBg(vec3 p)
{
    return starLayer(p.xy+vec2(4.8,0.),8.)*0.3;
}

float torus_sdf( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //映射到0~1之间
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv*2.  - 1.;	
    uv.x *= iResolution.x / iResolution.y;	
	vec3 eye = vec3(0.,0.2,-2);    //eye or camera postion 相机位置
    vec3 sd = vec3(uv.x,uv.y,-1); //screen coord 屏幕坐标
    vec3 ray_dir = normalize( sd - eye);//ray direction 射线方向
    
    vec3 col = vec3(0.);
    
	float hitbh = 0.;
    
    const int maxStep = 250;//光线最大步进数
    float st = 0.;      
    vec3 p = sd;
    vec3 v = ray_dir;
    float dt = 0.02;
    float GM = 0.8;   
    vec3 cp = black_hole_pos ;//+ 2.*vec3(1.*sin(iTime),sin(1.31*iTime),0.);
    float bc = 0.0;
    float hitbhglow = 0.;
    vec3 torCol = vec3(0);
    vec3 jetCol = vec3(0);
    for(int i = 0;i<maxStep;++i)
    {
        p += v * dt;
        vec3 relP = p - cp; //黑洞相对原点的位置       
        float r2 = dot(relP,relP);
        vec3 a = GM/r2 * normalize(-relP); //加速度的方向朝向黑洞，为-relP
        v += a * dt;   

        float hit = HitTest(relP); //hit表示距物体的最小距离
		hitbh = max(hitbh,smoothstep(0.02,-0.02,hit));  
        hitbhglow = max(hitbhglow,smoothstep(0.02,-0.05,hit));
        
        float glow = 0.01/r2;//0.01*(exp(0.2/r2)-0.5);
        
        bc += glow * (1.-hitbhglow) ;
        
        //吸积盘
        float rotangle = Pi/18.0;
                mat3 torRot = mat3(
            vec3(cos(rotangle),-sin(rotangle),0),
            vec3(sin(rotangle),cos(rotangle),0),
            vec3(0,0,1)
        );
        vec3 torpos = (torRot*relP);
        
        float tor = torus_sdf(torpos*vec3(1,13.,1.),vec2(1.8,1.2));
        float hitTor = smoothstep(0.,-0.01,tor);
        
        
        float v = smoothstep(0.,1.,length(torpos.xz)/18.);
        float u = atan(torpos.z,torpos.x)/Pi *v -iTime*0.03;
        
        vec2 toruv = vec2(u,v)*vec2(15,10.1);
        vec3 distor = texture(iChannel0,toruv).r*vec3(0.9,0.6,0.4);
        float fade = smoothstep(4.,1.5,length(torpos.xz));
		torCol += 0.025 *distor* hitTor*(1.-hitbh)*fade;

        //jets
        float jetHeight = smoothstep(0.,2.5, abs(torpos.y));
        vec3 blue = vec3(0.3,0.3,0.6);
        vec3 red = vec3(0.6,0.3,0.3);
        float jetWidth = 0.001/dot(torpos.xz,torpos.xz);
        
        //animation
        float t = iTime;
        float jetAnim = (0.5*sin(t+sin(t+sin(t+sin(t*2.))))+0.5) ;
        jetAnim = smoothstep(0.5,0.6,jetAnim);
        jetAnim = 12.5*jetAnim;
        
		jetCol += jetWidth*(1.-hitbh)
            	*mix(blue,red,jetHeight)
            	*smoothstep(jetAnim,0., abs(torpos.y));

    }
    //float dis = dot(p-cp,p-cp);
    //
    col = 0.23*bc*vec3(0.9,0.8,0.8) + GetBg(p)*(1.-hitbh) ;
    col += torCol;
    col += jetCol;
    fragColor = vec4(col,1.0);
}
