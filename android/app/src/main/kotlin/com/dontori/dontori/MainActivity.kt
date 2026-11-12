package com.dontori.dontori

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.glance.appwidget.updateAll
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.cancel

class MainActivity: FlutterActivity() {
    private lateinit var channel:MethodChannel
    private val scope=CoroutineScope(SupervisorJob()+Dispatchers.Main)
    private var pending:MethodChannel.Result?=null
    private var exportText:String?=null
    private var quickEntry=false

    override fun configureFlutterEngine(engine:FlutterEngine){
        super.configureFlutterEngine(engine)
        quickEntry=intent?.action=="com.dontori.QUICK_ENTRY"
        channel=MethodChannel(engine.dartExecutor.binaryMessenger,"com.dontori/platform")
        channel.setMethodCallHandler { call,result ->
            when(call.method){
                "consumeQuickEntry"->{result.success(quickEntry);quickEntry=false}
                "syncWidget"->{
                    val data=call.arguments as? Map<*,*>
                    if(data==null){result.error("invalid","Invalid widget data",null)}else{
                        getSharedPreferences("widget_display",MODE_PRIVATE).edit()
                            .putInt("petPoints",(data["petPoints"] as? Number)?.toInt()?:0)
                            .putBoolean("loggedToday",data["loggedToday"] as? Boolean?:false)
                            .putBoolean("configured",data["configured"] as? Boolean?:false)
                            .putLong("remaining",(data["remaining"] as? Number)?.toLong()?:0)
                            .putFloat("hp",(data["hp"] as? Number)?.toFloat()?:0f)
                            .putString("date",data["date"] as? String?:"")
                            .putBoolean("expired",data["expired"] as? Boolean?:false).apply()
                        scope.launch{try{DontoriWidget().updateAll(this@MainActivity);result.success(null)}
                            catch(e:Exception){result.error("widget",e.message,null)}}
                    }
                }
                "exportBackup","importBackup"->{
                    if(pending!=null){result.error("busy","File selection already active",null)}else{
                        pending=result
                        try{
                            if(call.method=="exportBackup"){
                                exportText=call.arguments as? String?:throw IllegalArgumentException("Missing backup")
                                val intent=Intent(Intent.ACTION_CREATE_DOCUMENT).apply{
                                    addCategory(Intent.CATEGORY_OPENABLE);type="application/json"
                                    putExtra(Intent.EXTRA_TITLE,"dontori-backup.json")
                                }
                                startActivityForResult(intent,2101)
                            }else{
                                startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT).apply{
                                    addCategory(Intent.CATEGORY_OPENABLE);type="*/*"
                                },2102)
                            }
                        }catch(e:Exception){pending=null;exportText=null;result.error("file",e.message,null)}
                    }
                }
                else->result.notImplemented()
            }
        }
    }
    override fun onNewIntent(intent:Intent){
        super.onNewIntent(intent);setIntent(intent)
        if(intent.action=="com.dontori.QUICK_ENTRY"){
            quickEntry=true
            if(::channel.isInitialized)channel.invokeMethod("quickEntry",null)
        }
    }
    @Deprecated("Android activity result bridge")
    override fun onActivityResult(requestCode:Int,resultCode:Int,data:Intent?){
        super.onActivityResult(requestCode,resultCode,data)
        if(requestCode!=2101&&requestCode!=2102)return
        val result=pending?:return
        pending=null
        val text=exportText;exportText=null
        val uri=data?.data
        if(resultCode!=Activity.RESULT_OK||uri==null){result.success(if(requestCode==2101)false else null);return}
        scope.launch(Dispatchers.IO){
            try{
                val value:Any?=if(requestCode==2101){
                    contentResolver.openOutputStream(uri,"wt")?.use{it.write((text?:error("Missing backup")).toByteArray(Charsets.UTF_8))}?:error("Cannot open file")
                    true
                }else{
                    contentResolver.openInputStream(uri)?.use{
                        val output=java.io.ByteArrayOutputStream()
                        val buffer=ByteArray(8192)
                        while(true){
                            val count=it.read(buffer)
                            if(count<0)break
                            require(output.size()+count<=10*1024*1024){"백업 파일은 10MB 이하여야 합니다."}
                            output.write(buffer,0,count)
                        }
                        val bytes=output.toByteArray()
                        String(bytes,Charsets.UTF_8)
                    }?:error("Cannot read file")
                }
                launch(Dispatchers.Main){result.success(value)}
            }catch(e:Exception){launch(Dispatchers.Main){result.error("file",e.message,null)}}
        }
    }
    override fun onDestroy(){
        pending?.error("closed","File picker closed",null);pending=null
        scope.cancel();super.onDestroy()
    }
}
