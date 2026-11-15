import AppKit
let root=CommandLine.arguments.count>1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath
let cards:[(Int,String,[String],String)]=[
(22,"朗伊尔城 · 科学与文化",["位于斯瓦尔巴群岛","城镇生活与极地研究并存","资料入口：挪威极地研究所"],"原创资料摘记 · 不是设施实拍"),
(24,"冰川照片怎样比较？",["地点：核对具体冰舌","时间：核对拍摄日期与季节","视角：同地点不等于同机位"],"原创资料摘记 · 来源：NVE冰川监测资料"),
(27,"食品标签 · 来自哪里？",["① 名称：面包","② 计量：克","③ 产地：挪威"],"原创虚构标签 · 非真实商品包装"),
(28,"挪威语的两种书面规范",["Bokmål","Nynorsk","书面规范不同于固定口音"],"原创术语卡 · 来源：挪威政府语言规范说明"),
(30,"故事也有版本",["谁讲述、整理或创作？","谁翻译？何时出版？","故事人物不等于真实历史人物"],"原创版本资料卡 · 来源：Nationalmuseum作品说明"),
(31,"两个年份 · 两件事",["1814 年 · 宪法历史","1905 年 · 与瑞典的联合解体","来源：挪威议会、挪威王室历史资料"],"原创事实摘记 · 不是档案原件"),
(32,"1940—1945 · 占领与解放",["1940 年 · 纳粹德国入侵","占领、迫害与抵抗","1945 年 · 解放与重建"],"原创事实摘记 · 来源：挪威议会二战历史资料"),
(35,"冰川怎样改变山谷？",["冰川运动 → 磨蚀与搬运","谷地逐渐加深、拓宽","冰退后 → 地形显露"],"原创过程卡 · 非同机位历史照片 · UNESCO / NVE"),
(36,"木屋的年代需要哪些证据？",["布吕根曾经历火灾","重建与修复可能更换材料","旧样式 ≠ 每块木材同样古老"],"原创证据卡 · 来源：UNESCO布吕根遗产资料")]
for (n,title,lines,footer) in cards{
 let img=NSImage(size:NSSize(width:960,height:600));img.lockFocus()
 NSColor(calibratedRed:0.95,green:0.97,blue:0.99,alpha:1).setFill();NSRect(x:0,y:0,width:960,height:600).fill()
 func text(_ s:String,_ y:Double,_ size:Double,_ bold:Bool=false){(s as NSString).draw(at:NSPoint(x:55,y:y),withAttributes:[.font:bold ? NSFont.boldSystemFont(ofSize:size):NSFont.systemFont(ofSize:size),.foregroundColor:NSColor(calibratedRed:0.07,green:0.22,blue:0.35,alpha:1)])}
 text(title,510,36,true)
 for (i,line) in lines.enumerated(){NSColor.white.setFill();NSBezierPath(roundedRect:NSRect(x:35,y:Double(365-i*110),width:890,height:90),xRadius:18,yRadius:18).fill();text(line,Double(386-i*110),30,true)}
 text(footer,35,22)
 img.unlockFocus();let rep=NSBitmapImageRep(data:img.tiffRepresentation!)!;try rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:root+String(format:"/assets/atlas/norway-m%02d.png",n)))
}
// Original public-space illustration; no claim of an actual street or standard dimensions.
do {
 let img=NSImage(size:NSSize(width:960,height:600));img.lockFocus()
 NSColor(calibratedWhite:0.96,alpha:1).setFill();NSRect(x:0,y:0,width:960,height:600).fill()
 func text(_ s:String,_ x:Double,_ y:Double,_ size:Double){(s as NSString).draw(at:NSPoint(x:x,y:y),withAttributes:[.font:NSFont.boldSystemFont(ofSize:size),.foregroundColor:NSColor(calibratedRed:0.07,green:0.22,blue:0.35,alpha:1)])}
 text("公共空间 · 找到缓坡",50,515,36)
 let ramp=NSBezierPath();ramp.move(to:NSPoint(x:50,y:160));ramp.line(to:NSPoint(x:330,y:320));ramp.line(to:NSPoint(x:330,y:160));ramp.close();NSColor(calibratedRed:1,green:0.6,blue:0.24,alpha:1).setFill();ramp.fill()
 NSColor(calibratedRed:0.16,green:0.54,blue:0.74,alpha:1).setFill()
 for i in 0..<4 {NSRect(x:400+i*45,y:160,width:45,height:40+i*40).fill()}
 NSRect(x:755,y:160,width:12,height:190).fill();NSRect(x:680,y:320,width:165,height:80).fill()
 text("① 缓坡",100,100,28);text("② 台阶",410,100,28);text("③ 站牌",680,100,28)
 text("原创虚构示意 · 仅辨认形态，非现场照片或工程标准",40,30,23)
 img.unlockFocus();let rep=NSBitmapImageRep(data:img.tiffRepresentation!)!;try rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:root+"/assets/atlas/norway-m37.png"))
}
