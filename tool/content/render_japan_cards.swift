// Original editorial diagrams, not documentary photographs.
// Run: swift -module-cache-path /private/tmp/japan-swift tool/content/render_japan_cards.swift
import AppKit
let out=URL(fileURLWithPath:FileManager.default.currentDirectoryPath).appendingPathComponent("assets/atlas")
let navy=NSColor(calibratedRed:0.07,green:0.22,blue:0.36,alpha:1)
let orange=NSColor(calibratedRed:1,green:0.60,blue:0.24,alpha:1)
func label(_ text:String,_ x:CGFloat,_ y:CGFloat,_ size:CGFloat,_ color:NSColor){(text as NSString).draw(at:NSPoint(x:x,y:y),withAttributes:[.font:NSFont.systemFont(ofSize:size,weight:.semibold),.foregroundColor:color])}
func box(_ x:CGFloat,_ y:CGFloat,_ w:CGFloat,_ h:CGFloat,_ color:NSColor){color.setFill();NSBezierPath(roundedRect:NSRect(x:x,y:y,width:w,height:h),xRadius:22,yRadius:22).fill()}
let cards:[(String,String,String,[String],[String])]=[
("language","日语的三种文字","观察字形，再听读音",["山","あ","ア"],["汉字","平假名","片假名"]),
("school","学习，也学习合作","课堂之外，还有共同完成的事",["阅读","用餐","整理"],["学习知识","分工合作","照顾空间"]),
("food","餐桌里的许多选择","一个例子，不能代表每个人的菜单",["主食","配菜","汤"],["来自原料","经过劳动","组成一餐"]),
("stage","舞台上的合作","用动作、讲述与音乐共同表达",["动作","故事","音乐"],["操纵人偶","叙述情节","配合节奏"]),
("labels","读懂一张市场标签","虚构练习 · 不是照片中的真实商品",["① 名称","② 单位","③ 产地"],["苹果","千克","日本"]),
("pottery","物件怎样成为历史线索","记录可见部分，保留尚待验证的问题",["形状","痕迹","背景"],["画下轮廓","比较纹样","查出土记录"]),
("rice","从稻谷到米饭","原料 · 加工 · 烹煮",["稻谷","米粒","米饭"],["收获","去壳碾磨","加水受热"]),
("miso","看见发酵的关系","制作条件需要资料与记录",["原料","参与者","过程"],["大豆 / 盐 / 曲","微生物","条件与时间"]),
("woodblock","让颜色对齐","原创套印关系图",["第一色","第二色","组合"],["圆形色版","波纹色版","对齐套印"]),
("origami","一张纸的变化","折叠后，材料还是纸",["平面","折痕","立体"],["观察纸面","对齐步骤","换个角度看"]),
]
for (key,title,subtitle,big,small) in cards{
 let image=NSImage(size:NSSize(width:960,height:600));image.lockFocus()
 NSColor(calibratedRed:0.95,green:0.97,blue:0.99,alpha:1).setFill();NSRect(x:0,y:0,width:960,height:600).fill()
 box(48,482,8,52,orange);label(title,80,484,42,navy);label(subtitle,80,432,25,navy)
 for i in 0..<3 {let x=CGFloat(54+i*302);box(x,140,278,238,NSColor.white);box(x+20,320,45,38,i==2 ? orange:navy);label(String(i+1),x+34,326,20,NSColor.white);label(big[i],x+30,231,42,navy);label(small[i],x+30,177,25,navy)}
 label("原创学习图示 · 非实拍 / 非历史原物",64,62,22,navy)
 image.unlockFocus();let rep=NSBitmapImageRep(data:image.tiffRepresentation!)!;try rep.representation(using:.png,properties:[:])!.write(to:out.appendingPathComponent("japan-card-\(key).png"))
}
