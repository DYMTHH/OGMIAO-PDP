<link rel="stylesheet" href="/plugins/addons/{$GzhxPluginPath}/template/assets/css/bootstrap-icons.css">
<link rel="stylesheet" href="/plugins/addons/{$GzhxPluginPath}/template/assets/css/bootstrap-scoped.css">
<link rel="stylesheet" href="/plugins/addons/{$GzhxPluginPath}/template/css/bootstrap-ui.css">
<section class="admin-main">
    <div class="apple-container">
        <div class="apple-nav">
            <span class="apple-nav-divider"></span>
            {foreach $PluginsAdminMenu as $v}
                {if $v['custom']}
                    <a href="{$v.url}" target="_blank">{$v.name}</a>
                {else/}
                    <a href="{$v.url}">{$v.name}</a>
                {/if}
            {/foreach}
        </div>
        <div class="apple-section">
            <div id="server-product"></div>
        </div>
    </div>
</section>
<div class="apple-toast-container" id="toastContainer"></div>
<div id="appleLoadingOverlay">
    <div class="apple-spinner"></div>
</div>
<script>
(function(){
    let UpstreamUrl='{$UpstreamUrl|default=""}';
    let showToast=function(type, message){
        let container=document.getElementById('toastContainer');
        let toastEl=document.createElement('div');
        toastEl.className='apple-toast apple-toast-'+type+' show';
        toastEl.innerHTML='<div class="apple-toast-content"><i class="bi '+(type==='success'?'bi-check-circle-fill" style="color:#34c759':type==='error'?'bi-x-circle-fill" style="color:#ff3b30':type==='warning'?'bi-exclamation-circle-fill" style="color:#ff9500':'bi-info-circle-fill" style="color:#2563eb')+' me-2"></i><span>'+message+'</span></div>';
        container.appendChild(toastEl);
        setTimeout(function(){ toastEl.remove(); }, 3000);
    };
    let Loading={
        show: function(){
            let overlay=document.getElementById('appleLoadingOverlay');
            overlay.classList.add('show');
        },
        hide: function(){
            let overlay=document.getElementById('appleLoadingOverlay');
            overlay.classList.remove('show');
        }
    };
    let queryToJson=function (hash){
        let str=hash?window.location.hash:window.location.search
        if( !str ) return { };
        if(str) str=str.substr(1);
        if( !str ) return { };
        let arr = str.split('&');
        let data={ };
        $.each( arr, function (k,v) {
            if(v.indexOf("=")>-1){
                let d=v.indexOf("=");
                data[ decodeURIComponent(v.substr(0,d)) ]=decodeURIComponent(v.substr(d+1));
            }
        });
        return data;
    }
    let ajaxWithRetry=function(option, retryCount){
        retryCount=retryCount||0;
        let maxRetries=option.maxRetries||3;
        let retryDelay=option.retryDelay||2000;
        Loading.show(option.load||"加载中...");
        $.ajax({
            dataType: "json",
            type: option.type||"post",
            headers: {
                "X-Requested-With": "XMLHttpRequest",
            },
            url: option.url||"",
            data:option.data,
            async:true,
            timeout: option.timeout||300000,
            success: function (t) {
                Loading.hide();
                if( t.status==1 || t.status==200 ){
                    if(option.success)  option.success(t.info || t.data || t);
                }else{
                    if(option.error){
                        option.error(t.info || t.msg);
                    }else{
                        showToast('error', t.info || t.msg);
                    }
                }
            },
            error: function (request, status, errorThrown) {
                console.error('AJAX error:', status, errorThrown, 'Retry:', retryCount);
                if(retryCount<maxRetries && status!=='abort'){
                    showToast('warning', "请求失败，"+(retryDelay/1000)+"秒后重试("+(retryCount+1)+"/"+maxRetries+")");
                    setTimeout(function(){
                        ajaxWithRetry(option, retryCount+1);
                    }, retryDelay);
                }else{
                    Loading.hide();
                    if(status==='timeout'){
                        showToast('error', "请求超时，已重试"+maxRetries+"次");
                    }else{
                        if(option.error){
                            option.error("网络错误");
                        }else{
                            showToast('error', "网络错误，已重试"+maxRetries+"次");
                        }
                    }
                }
            }
        });
    };
    let ajax=function (option){
        ajaxWithRetry(option, 0);
    }
    let escapeHtml=function(text){
        if(text===null || text===undefined) return '';
        let map={
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#039;'
        };
        return String(text).replace(/[&<>"']/g, function(m){ return map[m]; });
    };
    let safeString=function(val, defaultVal){
        if(val===null || val===undefined || val==='') return defaultVal || '';
        return String(val);
    };
    let safeNumber=function(val, defaultVal){
        let num=parseFloat(val);
        return isNaN(num) ? (defaultVal || 0) : num;
    };
    let safeId=function(val){
        if(val===null || val===undefined || val==='') return '';
        return String(val);
    };
    let normalizeProduct=function(product){
        if(!product || typeof product!=='object') return null;
        let normalized={
            id: safeId(product.id),
            name: safeString(product.name, '未命名商品'),
            type: safeString(product.type, 'unknown'),
            description: safeString(product.description, ''),
            raw: product
        };
        $.each(product, function(key, value){
            if(!normalized.hasOwnProperty(key) && key!=='raw'){
                if(value===null || value===undefined){
                    normalized[key]='';
                }else if(typeof value==='object'){
                    normalized[key]=JSON.stringify(value);
                }else{
                    normalized[key]=String(value);
                }
            }
        });
        return normalized;
    };
    let normalizeGroup=function(group){
        if(!group || typeof group!=='object') return null;
        let products=[];
        if(group.products && Array.isArray(group.products)){
            $.each(group.products, function(k, p){
                let np=normalizeProduct(p);
                if(np) products.push(np);
            });
        }
        let normalized={
            id: safeId(group.id),
            name: safeString(group.name, '未命名分组'),
            products: products,
            raw: group
        };
        $.each(group, function(key, value){
            if(!normalized.hasOwnProperty(key) && key!=='raw' && key!=='products'){
                if(value===null || value===undefined){
                    normalized[key]='';
                }else if(typeof value==='object'){
                    normalized[key]=JSON.stringify(value);
                }else{
                    normalized[key]=String(value);
                }
            }
        });
        return normalized;
    };
    let validateAndNormalizeData=function(data){
        let log=[];
        log.push('['+new Date().toLocaleTimeString()+'] 开始数据处理');
        log.push('接收数据类型: '+(Array.isArray(data)?'数组':typeof data));
        if(!data || typeof data!=='object'){
            log.push('错误：数据为空或类型错误');
            console.error('Invalid data received:', data);
            GlobalData.processLog=log;
            return { groups: [], clientProducts: {}, rate: 1 };
        }
        let groups=[];
        let serverDataArray=null;
        let rawGroupCount=0;
        let rawProductCount=0;
        if(data.server && data.server.data && Array.isArray(data.server.data)){
            serverDataArray=data.server.data;
            log.push('数据结构: data.server.data (数组)');
        }else if(data.server && Array.isArray(data.server)){
            serverDataArray=data.server;
            log.push('数据结构: data.server (数组)');
        }else if(data.data && Array.isArray(data.data)){
            serverDataArray=data.data;
            log.push('数据结构: data.data (数组)');
        }else if(Array.isArray(data)){
            serverDataArray=data;
            log.push('数据结构: data (数组)');
        }else{
            log.push('警告：无法识别数据结构');
            log.push('data keys: '+Object.keys(data).join(', '));
            if(data.server){
                log.push('data.server keys: '+Object.keys(data.server).join(', '));
            }
        }
        if(serverDataArray && serverDataArray.length>0){
            rawGroupCount=serverDataArray.length;
            log.push('原始数据：'+rawGroupCount+'个商品组');
            let skippedGroups=[];
            let skippedProducts=[];
            $.each(serverDataArray, function(k, g){
                let ng=normalizeGroup(g);
                if(ng){
                    let validProducts=[];
                    if(g.products && Array.isArray(g.products)){
                        rawProductCount+=g.products.length;
                        $.each(g.products, function(pk, p){
                            if(p && p.id){
                                validProducts.push(p);
                            }else{
                                skippedProducts.push('组['+(g.name||g.id||k)+']商品['+pk+']: 缺少ID');
                            }
                        });
                    }
                    if(validProducts.length>0){
                        groups.push(ng);
                    }else{
                        skippedGroups.push('组['+(g.name||g.id||k)+']: 无有效商品');
                    }
                }else{
                    skippedGroups.push('组['+k+']: 标准化失败');
                }
            });
            if(skippedGroups.length>0){
                log.push('跳过的商品组('+skippedGroups.length+')：'+skippedGroups.slice(0,5).join('; ')+(skippedGroups.length>5?'...':''));
            }
            if(skippedProducts.length>0){
                log.push('跳过的商品('+skippedProducts.length+')：'+skippedProducts.slice(0,5).join('; ')+(skippedProducts.length>5?'...':''));
            }
        }else{
            log.push('警告：serverDataArray 为空或不存在');
        }
        log.push('处理后：'+groups.length+'个商品组，共'+rawProductCount+'个商品');
        let clientProducts={};
        if(data.client && typeof data.client==='object'){
            clientProducts=data.client;
            let clientKeys=Object.keys(clientProducts).filter(function(id){ return id!=='null'; });
            log.push('本地已导入商品：'+clientKeys.length+'个');
        }
        let rate=safeNumber(data.server && data.server.rate, 1);
        if(rate<=0) rate=1;
        log.push('汇率：'+rate);
        let productTypeMap={};
        if(data.server && data.server.product_type && typeof data.server.product_type==='object'){
            productTypeMap=data.server.product_type;
            log.push('商品类型映射：'+Object.keys(productTypeMap).length+'种');
        }else if(data.product_type && typeof data.product_type==='object'){
            productTypeMap=data.product_type;
            log.push('商品类型映射：'+Object.keys(productTypeMap).length+'种');
        }
        log.push('['+new Date().toLocaleTimeString()+'] 数据处理完成');
        GlobalData.processLog=log;
        let localDomain=data.local_domain || '';
        return { groups: groups, clientProducts: clientProducts, rate: rate, productTypeMap: productTypeMap, localDomain: localDomain };
    };
    let GlobalData={
        groups: [],
        filteredGroups: [],
        Groups: [],
        GroupsRaw: [],
        Menu: [],
        MenuType: {},
        ProductTypeMap: {},
        upstreamUrl: UpstreamUrl,
        localDomain: '',
        rate: 1,
        currentPage: 1,
        pageSize: 20,
        query: {},
        rawData: null,
        clientProducts: {},
        searchKeyword: '',
        searchProductKeyword: '',
        importFilter: 'all',
        processLog: [],
        dataValidation: {
            isValid: false,
            lastCheckTime: null,
            totalServerProducts: 0,
            totalClientProducts: 0,
            missingProducts: [],
            extraProducts: [],
            errorMessage: ''
        }
    };
    let getProductTypeName=function(type){
        if(GlobalData.ProductTypeMap && GlobalData.ProductTypeMap[type]){
            return GlobalData.ProductTypeMap[type];
        }
        return type || '未知';
    };
    let validateDataIntegrity=function(rawResponse, clientData){
        let validation={
            isValid: true,
            totalServerProducts: 0,
            totalClientProducts: 0,
            missingProducts: [],
            extraProducts: [],
            errorMessage: ''
        };
        let serverData=null;
        if(rawResponse && rawResponse.server && rawResponse.server.data){
            serverData=rawResponse.server.data;
        }else if(rawResponse && rawResponse.data && Array.isArray(rawResponse.data)){
            serverData=rawResponse.data;
        }else if(rawResponse && Array.isArray(rawResponse)){
            serverData=rawResponse;
        }
        if(!serverData || !Array.isArray(serverData)){
            validation.isValid=false;
            validation.errorMessage='服务器数据为空';
            return validation;
        }
        let serverProductIds=[];
        $.each(serverData, function(k, group){
            if(group.products && Array.isArray(group.products)){
                $.each(group.products, function(pk, product){
                    if(product.id){
                        serverProductIds.push(String(product.id));
                    }
                });
            }
        });
        validation.totalServerProducts=serverProductIds.length;
        let clientProductIds=Object.keys(clientData || {}).filter(function(id){ return id!=='null'; });
        validation.totalClientProducts=clientProductIds.length;
        let missingIds=[];
        $.each(clientProductIds, function(i, id){
            if(serverProductIds.indexOf(id)===-1){
                missingIds.push(id);
            }
        });
        validation.extraProducts=missingIds.slice(0, 10);
        if(validation.totalServerProducts===0){
            validation.isValid=false;
            validation.errorMessage='服务器返回的商品数据为空';
        }
        if(validation.extraProducts.length>0){
            validation.isValid=false;
            validation.errorMessage='发现'+missingIds.length+'个本地商品不在上游数据中';
        }
        return validation;
    };
    let verifyDataWithRetry=function(callback, retryCount){
        retryCount=retryCount||0;
        let maxRetries=3;
        let query=GlobalData.query;
        Loading.show("验证数据完整性...");
        $.ajax({
            url: './get_upstream_products?id='+query.id+'&languagesys=CN&request_time='+new Date().getTime(),
            type: "GET",
            timeout: 120000,
            success: function (t) {
                Loading.hide();
                if(t.status==200){
                    let validation=validateDataIntegrity(t.data || t, GlobalData.clientProducts);
                    validation.lastCheckTime=new Date().toLocaleString();
                    GlobalData.dataValidation=validation;
                    if(callback) callback(validation);
                }else{
                    if(retryCount<maxRetries){
                        showToast('warning', "验证失败，重试中("+(retryCount+1)+"/"+maxRetries+")");
                        setTimeout(function(){ verifyDataWithRetry(callback, retryCount+1); }, 2000);
                    }else{
                        GlobalData.dataValidation.isValid=false;
                        GlobalData.dataValidation.errorMessage=t.msg || "验证失败";
                        if(callback) callback(GlobalData.dataValidation);
                    }
                }
            },
            error: function(){
                if(retryCount<maxRetries){
                    showToast('warning', "验证失败，重试中("+(retryCount+1)+"/"+maxRetries+")");
                    setTimeout(function(){ verifyDataWithRetry(callback, retryCount+1); }, 2000);
                }else{
                    Loading.hide();
                    GlobalData.dataValidation.isValid=false;
                    GlobalData.dataValidation.errorMessage="网络错误";
                    if(callback) callback(GlobalData.dataValidation);
                }
            }
        });
    };
    let calculateStats=function(){
        let totalProducts=0;
        let filteredProducts=0;
        $.each(GlobalData.groups, function(k, v){
            totalProducts += (v.products || []).length;
        });
        $.each(GlobalData.filteredGroups, function(k, v){
            filteredProducts += (v.products || []).length;
        });
        return {
            totalGroups: GlobalData.groups.length,
            totalProducts: totalProducts,
            filteredGroups: GlobalData.filteredGroups.length,
            filteredProducts: filteredProducts,
            imported: Object.keys(GlobalData.clientProducts || {}).length
        };
    }
    let highlightText=function(text, keyword){
        if(!keyword) return text;
        let regex=new RegExp('('+keyword.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')+')', 'gi');
        return String(text).replace(regex, '<span class="apple-highlight">$1</span>');
    }
    let filterData=function(){
        let groupKeyword=GlobalData.searchKeyword.toLowerCase();
        let productKeyword=GlobalData.searchProductKeyword.toLowerCase();
        let importFilter=GlobalData.importFilter;
        if(!groupKeyword && !productKeyword && importFilter==='all'){
            GlobalData.filteredGroups=JSON.parse(JSON.stringify(GlobalData.groups));
            return;
        }
        GlobalData.filteredGroups=[];
        $.each(GlobalData.groups, function(k, v){
            let groupName=String(v.name).toLowerCase();
            let matchGroup=groupKeyword && groupName.indexOf(groupKeyword)!==-1;
            let filteredProducts=[];
            if(v.products && v.products.length>0){
                $.each(v.products, function(pk, pv){
                    let productName=String(pv.name).toLowerCase();
                    let productType=String(pv.type).toLowerCase();
                    let clientHas=GlobalData.clientProducts && GlobalData.clientProducts.hasOwnProperty(pv.id);
                    let matchImportFilter=true;
                    if(importFilter==='imported'){
                        matchImportFilter=clientHas;
                    }else if(importFilter==='not_imported'){
                        matchImportFilter=!clientHas;
                    }
                    let matchProduct=!productKeyword || 
                        productName.indexOf(productKeyword)!==-1 || 
                        productType.indexOf(productKeyword)!==-1;
                    if(matchProduct && matchImportFilter){
                        filteredProducts.push(pv);
                    }
                });
            }
            if(matchGroup || (productKeyword && filteredProducts.length>0) || (!groupKeyword && !productKeyword)){
                let groupCopy=JSON.parse(JSON.stringify(v));
                if(productKeyword || importFilter!=='all'){
                    groupCopy.products=filteredProducts;
                }
                if(groupCopy.products && groupCopy.products.length>0){
                    GlobalData.filteredGroups.push(groupCopy);
                }
            }
        });
    }
    let renderStats=function(){
        let stats=calculateStats();
        let validation=GlobalData.dataValidation;
        let validationStatus=validation.isValid?'<span style="color:#34c759;"><i class="bi bi-check-circle-fill"></i> 数据完整</span>':'<span style="color:#ff9500;"><i class="bi bi-exclamation-circle-fill"></i> '+escapeHtml(validation.errorMessage||'待验证')+'</span>';
        let html='<div class="apple-stats">';
        html+='<div class="apple-stats-item"><strong>'+stats.totalGroups+'</strong><span>商品组</span></div>';
        html+='<div class="apple-stats-item"><strong>'+stats.totalProducts+'</strong><span>商品</span></div>';
        html+='<div class="apple-stats-item"><strong>'+stats.imported+'</strong><span>已导入</span></div>';
        html+='<div class="apple-stats-item"><strong>'+(stats.totalProducts-stats.imported)+'</strong><span>待导入</span></div>';
        html+='<div class="apple-stats-item" style="min-width:120px;">'+validationStatus+'</div>';
        html+='<div style="display:flex;gap:6px;margin-left:auto;">';
        html+='<button type="button" class="apple-btn apple-btn-secondary apple-btn-sm" id="verifyData" title="验证数据完整性"><i class="bi bi-shield-check"></i></button>';
        html+='<button type="button" class="apple-btn apple-btn-secondary apple-btn-sm" id="toggleDebug" title="调试"><i class="bi bi-bug"></i></button>';
        html+='<button type="button" class="apple-btn apple-btn-secondary apple-btn-sm" id="reloadData" title="刷新"><i class="bi bi-arrow-clockwise"></i></button>';
        html+='</div>';
        html+='</div>';
        return html;
    }
    let renderSearchBox=function(){
        let html='<div class="apple-search-bar">';
        html+='<label>搜索</label><input type="text" class="apple-input" id="searchGroup" placeholder="商品组" value="'+GlobalData.searchKeyword+'">';
        html+='<input type="text" class="apple-input" id="searchProduct" placeholder="商品" value="'+GlobalData.searchProductKeyword+'">';
        html+='<select class="apple-select" id="importFilter">';
        html+='<option value="all" '+(GlobalData.importFilter==='all'?'selected':'')+'>全部</option>';
        html+='<option value="imported" '+(GlobalData.importFilter==='imported'?'selected':'')+'>已对接</option>';
        html+='<option value="not_imported" '+(GlobalData.importFilter==='not_imported'?'selected':'')+'>未对接</option>';
        html+='</select>';
        html+='<button type="button" class="apple-btn apple-btn-primary apple-btn-sm" id="doSearch"><i class="bi bi-search"></i></button>';
        html+='<button type="button" class="apple-btn apple-btn-secondary apple-btn-sm" id="resetSearch"><i class="bi bi-x"></i></button>';
        html+='</div>';
        return html;
    }
    let renderDebugPanel=function(){
        let stats=calculateStats();
        let validation=GlobalData.dataValidation;
        let rawData=GlobalData.rawData;
        let rawJsonStr=JSON.stringify(rawData, null, 2);
        let rawJsonLen=rawJsonStr.length;
        let rawGroups=0;
        let rawProducts=0;
        let serverDataArray=null;
        if(rawData && rawData.data && Array.isArray(rawData.data)){
            serverDataArray=rawData.data;
        }else if(rawData && Array.isArray(rawData)){
            serverDataArray=rawData;
        }
        if(serverDataArray){
            rawGroups=serverDataArray.length;
            $.each(serverDataArray, function(k, g){
                if(g.products && Array.isArray(g.products)){
                    rawProducts+=g.products.length;
                }
            });
        }
        let processedGroups=GlobalData.groups.length;
        let processedProducts=0;
        $.each(GlobalData.groups, function(k, g){
            processedProducts+=(g.products || []).length;
        });
        let dataLossWarning='';
        if(rawGroups!==processedGroups || rawProducts!==processedProducts){
            dataLossWarning='<p style="color:#ff3b30;font-weight:bold;"><i class="bi bi-exclamation-triangle-fill"></i> 警告：数据处理过程中存在丢失！</p>';
            dataLossWarning+='<p style="color:#ff9500;">原始: '+rawGroups+'组/'+rawProducts+'商品 → 处理后: '+processedGroups+'组/'+processedProducts+'商品</p>';
        }else if(rawGroups>0 || rawProducts>0){
            dataLossWarning='<p style="color:#34c759;"><i class="bi bi-check-circle-fill"></i> 数据完整，无丢失</p>';
        }
        let html='<div class="apple-debug" id="debugPanel" style="display:none;">';
        html+='<h5>数据统计</h5>';
        html+='<p>商品组: '+stats.totalGroups+' | 商品: '+stats.totalProducts+' | 已导入: '+stats.imported+'</p>';
        html+='<h5>数据验证</h5>';
        html+='<p>状态: '+(validation.isValid?'<span style="color:#34c759;">有效</span>':'<span style="color:#ff3b30;">无效</span>')+' | 上次检查: '+(validation.lastCheckTime||'未检查')+'</p>';
        html+='<p>上游商品: '+validation.totalServerProducts+' | 本地已导入: '+validation.totalClientProducts+'</p>';
        if(validation.extraProducts && validation.extraProducts.length>0){
            html+='<p style="color:#ff9500;">本地多余商品ID: '+validation.extraProducts.join(', ')+'...</p>';
        }
        html+='<h5>数据完整性检查</h5>';
        html+='<p>原始数据: '+rawGroups+'组/'+rawProducts+'商品 | 处理后: '+processedGroups+'组/'+processedProducts+'商品</p>';
        html+=dataLossWarning;
        if(GlobalData.upstreamUrl || GlobalData.localDomain){
            html+='<h5>URL配置</h5>';
            if(GlobalData.upstreamUrl){
                html+='<p style="font-size:12px;color:#666;">上游: <a href="'+GlobalData.upstreamUrl+'" target="_blank">'+escapeHtml(GlobalData.upstreamUrl)+'</a></p>';
            }
            if(GlobalData.localDomain){
                html+='<p style="font-size:12px;color:#666;">本地: <a href="'+GlobalData.localDomain+'" target="_blank">'+escapeHtml(GlobalData.localDomain)+'</a></p>';
            }
        }
        if(GlobalData.ProductTypeMap && Object.keys(GlobalData.ProductTypeMap).length>0){
            html+='<h5>商品类型映射</h5>';
            let typeMapHtml='';
            $.each(GlobalData.ProductTypeMap, function(key, value){
                typeMapHtml+=key+' → '+value+'; ';
            });
            html+='<p style="font-size:12px;color:#666;">'+escapeHtml(typeMapHtml.trim())+'</p>';
        }
        html+='<h5>原始数据 (JSON大小: '+(rawJsonLen/1024).toFixed(2)+'KB)</h5>';
        html+='<div style="margin-bottom:10px;">';
        html+='<button type="button" class="apple-btn apple-btn-secondary apple-btn-sm" id="copyRawJson"><i class="bi bi-clipboard"></i> 复制完整JSON</button> ';
        html+='<button type="button" class="apple-btn apple-btn-secondary apple-btn-sm" id="downloadRawJson"><i class="bi bi-download"></i> 下载JSON</button> ';
        html+='<button type="button" class="apple-btn apple-btn-secondary apple-btn-sm" id="toggleRawJson"><i class="bi bi-eye"></i> 展开/折叠</button>';
        html+='</div>';
        html+='<pre id="rawJsonPreview" style="max-height:300px;overflow:auto;display:none;">'+escapeHtml(rawJsonStr)+'</pre>';
        html+='<pre id="rawJsonTruncated" style="max-height:200px;overflow:auto;">'+escapeHtml(rawJsonStr.substring(0, 3000))+(rawJsonLen>3000?'...\n\n[已截断，完整数据共'+rawJsonLen+'字符，请点击上方按钮复制或下载]':'')+'</pre>';
        html+='<h5>数据处理日志</h5>';
        html+='<div id="dataProcessLog" style="max-height:150px;overflow:auto;background:#f5f5f5;padding:10px;border-radius:4px;font-size:12px;">';
        if(GlobalData.processLog && GlobalData.processLog.length>0){
            $.each(GlobalData.processLog, function(i, log){
                html+='<div style="margin-bottom:4px;">'+escapeHtml(log)+'</div>';
            });
        }else{
            html+='<div style="color:#999;">暂无处理日志</div>';
        }
        html+='</div>';
        html+='</div>';
        return html;
    }
    let renderPagination=function(position, total, currentPage, totalPages){
        let html='<div class="apple-pagination apple-pagination-'+position+'">';
        html+='<div class="apple-pagination-info">共 <strong>'+total+'</strong> 组 | 第 <strong>'+currentPage+'</strong>/<strong>'+totalPages+'</strong> 页</div>';
        html+='<div class="apple-pagination-btns">';
        html+='<button class="group-prev-page" data-pos="'+position+'" '+(currentPage<=1?'disabled':'')+'><i class="bi bi-chevron-left"></i></button>';
        let pageStart=Math.max(1, currentPage-2);
        let pageEnd=Math.min(totalPages, pageStart+4);
        if(pageEnd-pageStart<4) pageStart=Math.max(1, pageEnd-4);
        for(let i=pageStart;i<=pageEnd;i++){
            html+='<button class="group-page-num '+(i==currentPage?'active':'')+'" data-page="'+i+'" data-pos="'+position+'">'+i+'</button>';
        }
        html+='<button class="group-next-page" data-pos="'+position+'" '+(currentPage>=totalPages?'disabled':'')+'><i class="bi bi-chevron-right"></i></button>';
        html+='</div>';
        html+='<select class="apple-select apple-page-size-select">';
        html+='<option value="10" '+(GlobalData.pageSize==10?'selected':'')+'>10/页</option>';
        html+='<option value="20" '+(GlobalData.pageSize==20?'selected':'')+'>20/页</option>';
        html+='<option value="50" '+(GlobalData.pageSize==50?'selected':'')+'>50/页</option>';
        html+='<option value="100" '+(GlobalData.pageSize==100?'selected':'')+'>100/页</option>';
        html+='</select>';
        html+='</div>';
        return html;
    }
    let renderGroupList=function(){
        filterData();
        let groups=GlobalData.filteredGroups;
        let total=groups.length;
        let currentPage=GlobalData.currentPage;
        let pageSize=GlobalData.pageSize;
        let totalPages=Math.ceil(total/pageSize) || 1;
        if(currentPage>totalPages) currentPage=totalPages;
        if(currentPage<1) currentPage=1;
        GlobalData.currentPage=currentPage;
        let start=(currentPage-1)*pageSize;
        let end=start+pageSize;
        let pageGroups=groups.slice(start, end);
        let html='';
        html+='<div class="apple-tip">';
        html+='<h4><i class="bi bi-lightbulb"></i> 提示</h4>';
        html+='<p>新建分组在商品中【默认分组】下，如需要调整请导入后到商品列表中自行调整</p>';
        html+='<div class="inline-form">';
        html+='<label>利润(%):</label><input type="text" class="apple-input" name="profit" value="0">';
        html+='<label>汇率:</label><input type="text" class="apple-input" name="rate" value="'+GlobalData.rate+'">';
        html+='</div>';
        html+='</div>';
        html+=renderSearchBox();
        html+=renderStats();
        html+=renderDebugPanel();
        if(total>pageSize){
            html+=renderPagination('top', total, currentPage, totalPages);
        }else if(total>0){
            html+='<div class="apple-pagination apple-pagination-top"><div class="apple-pagination-info">共 <strong>'+total+'</strong> 个商品组</div></div>';
        }
        if(total===0){
            html+='<div class="apple-pagination apple-pagination-top"><div class="apple-pagination-info" style="color:#ff3b30;">未找到匹配的商品</div></div>';
        }
        $.each(pageGroups, function(k, v){
            let vid=v.id;
            let products=v.products || [];
            let productCount=products.length;
            let type='';
            let groupLinks='';
            if(GlobalData.upstreamUrl && vid){
                groupLinks=' <a href="'+GlobalData.upstreamUrl+'/cart?fid=9&gid='+vid+'" target="_blank" class="apple-btn apple-btn-sm apple-btn-link" title="查看上游商品组"><i class="bi bi-box-arrow-up-right"></i></a>';
            }
            let localGids={};
            $.each(products, function(pk, pv){
                let clientInfo=GlobalData.clientProducts && GlobalData.clientProducts[pv.id];
                if(clientInfo && clientInfo.gid){
                    localGids[clientInfo.gid]=true;
                }
            });
            let localGidKeys=Object.keys(localGids);
            if(localGidKeys.length>0 && GlobalData.localDomain){
                $.each(localGidKeys, function(i, localGid){
                    let localGroupName='';
                    if(GlobalData.GroupsRaw){
                        $.each(GlobalData.GroupsRaw, function(gk, gv){
                            if(String(gv.id)===String(localGid)){
                                localGroupName=gv.name;
                            }
                        });
                    }
                    groupLinks+=' <a href="'+GlobalData.localDomain+'/cart?gid='+localGid+'" target="_blank" class="apple-btn apple-btn-sm apple-btn-link apple-btn-local" title="查看本地商品组: '+escapeHtml(localGroupName)+'"><i class="bi bi-house"></i></a>';
                });
            }
            html+='<div class="apple-group" data-vid="'+vid+'">';
            html+='<div class="apple-group-header">';
            html+='<h5>'+highlightText(escapeHtml(v.name), GlobalData.searchKeyword)+' <span class="count">'+productCount+'</span>'+groupLinks+'</h5>';
            html+='<div class="actions">';
            html+='<div class="apple-select-wrapper" data-name="group'+escapeHtml(vid)+'" data-search="true">';
            html+='<div class="apple-select-display placeholder" tabindex="0">分组</div>';
            html+='<div class="apple-select-dropdown">';
            html+='<div class="apple-select-search"><input type="text" placeholder="搜索分组..."></div>';
            html+='<ul class="apple-select-options">';
            html+='<li data-value="" class="selected">分组</li>';
            html+='<li data-value="-1" class="create-new"><i class="bi bi-plus-circle"></i> 新建分组</li>';
            if(GlobalData.GroupsRaw){
                $.each(GlobalData.GroupsRaw, function(gk, gv){
                    html+='<li data-value="'+escapeHtml(safeId(gv.id))+'">'+escapeHtml(safeString(gv.name,''))+'</li>';
                });
            }
            html+='</ul></div></div>';
            html+='<select name="menu'+escapeHtml(vid)+'" class="apple-select" data-search="true">'+GlobalData.Menu.join('')+'</select>';
            html+='<button type="button" class="apple-btn apple-btn-primary apple-btn-sm update-files" data-vid="'+escapeHtml(vid)+'" data-type="'+escapeHtml(v.name)+'"><i class="bi bi-download"></i> 导入</button>';
            html+='</div>';
            html+='</div>';
            html+='<table class="apple-table">';
            html+='<thead><tr>';
            html+='<th style="width:30px;"><label class="apple-checkbox"><input type="checkbox" id="customCheckHead'+vid+'" checked></label></th>';
            html+='<th style="width:70px;">ID</th>';
            html+='<th style="width:150px;">商品名称</th>';
            html+='<th style="width:100px;">类型</th>';
            html+='<th>描述</th>';
            html+='<th style="width:60px;">操作</th>';
            html+='</tr></thead><tbody>';
            $.each(products, function(kk, vv){
                if(type==='') type=vv.type;
                let clientHas=GlobalData.clientProducts && GlobalData.clientProducts.hasOwnProperty(vv.id);
                let clientProductInfo=clientHas ? GlobalData.clientProducts[vv.id] : null;
                let localProductId=clientProductInfo ? (clientProductInfo.id || clientProductInfo.upstream_pid) : null;
                let productId=escapeHtml(safeId(vv.id));
                let productName=escapeHtml(safeString(vv.name, '未命名'));
                let productTypeRaw=safeString(vv.type, 'unknown');
                let productTypeDisplay=getProductTypeName(productTypeRaw);
                let productDesc=escapeHtml(safeString(vv.description, ''));
                let actionLinks='';
                if(GlobalData.upstreamUrl){
                    actionLinks+='<a href="'+GlobalData.upstreamUrl+'/cart?action=configureproduct&pid='+vv.id+'" target="_blank" class="apple-btn apple-btn-sm apple-btn-link" title="查看上游商品"><i class="bi bi-box-arrow-up-right"></i></a>';
                }
                if(clientHas && localProductId && GlobalData.localDomain){
                    actionLinks+='<a href="'+GlobalData.localDomain+'/cart?action=configureproduct&pid='+localProductId+'" target="_blank" class="apple-btn apple-btn-sm apple-btn-link apple-btn-local" title="查看本地商品"><i class="bi bi-house"></i></a>';
                }
                html+='<tr>';
                html+='<td>'+(clientHas?'<span class="apple-imported"><i class="bi bi-check-circle-fill"></i></span>':'<label class="apple-checkbox"><input type="checkbox" class="row-checkbox" value="'+productId+'" data-name="'+productName+'" data-vid="'+escapeHtml(vid)+'" checked></label>')+'</td>';
                html+='<td><span class="apple-badge apple-badge-gray">'+productId+'</span></td>';
                html+='<td><strong>'+highlightText(productName, GlobalData.searchProductKeyword)+'</strong></td>';
                html+='<td><span class="apple-badge apple-badge-info" title="'+escapeHtml(productTypeRaw)+'">'+highlightText(escapeHtml(productTypeDisplay), GlobalData.searchProductKeyword)+'</span></td>';
                html+='<td class="apple-truncate">'+(productDesc.length>60?productDesc.substring(0,60)+'...':productDesc||'-')+'</td>';
                html+='<td style="text-align:center;white-space:nowrap;">'+actionLinks+'</td>';
                html+='</tr>';
            });
            html+='</tbody></table>';
            html+='</div>';
        });
        if(total>pageSize){
            html+=renderPagination('bottom', total, currentPage, totalPages);
        }
        $('#server-product').html(html);
        $.each(pageGroups, function(k, v){
            let vid=v.id;
            let products=v.products || [];
            let type='';
            if(products.length>0) type=products[0].type;
            let typeDisplayName=getProductTypeName(type);
            if(GlobalData.MenuType[typeDisplayName]){
                $('select[name="menu'+vid+'"]').val(GlobalData.MenuType[typeDisplayName]);
            }else{
                switch (type){
                    case 'cdn':case 'cloud':case 'dcimcloud':
                        $('select[name="menu'+vid+'"]').val(GlobalData.MenuType['云服务器']);break;
                    case 'hostingaccount':
                        $('select[name="menu'+vid+'"]').val(GlobalData.MenuType['虚拟主机']);break;
                    case 'server':
                        $('select[name="menu'+vid+'"]').val(GlobalData.MenuType['独立服务器']);break;
                    case 'other':
                        $('select[name="menu'+vid+'"]').val(GlobalData.MenuType['其他']);break;
                    default:
                        $('select[name="menu'+vid+'"]').val(GlobalData.MenuType['云服务器']);
                }
            }
        });
        bindEvents();
    }
    let bindEvents=function(){
        $('input[id^="customCheckHead"]').off('click').on('click', function(){
            let self=$(this), checked=self.prop('checked');
            self.closest('.apple-group').find('tbody input[type="checkbox"]').prop('checked',checked);
        });
        $('.group-prev-page').off('click').on('click', function(){
            if(GlobalData.currentPage>1){
                GlobalData.currentPage--;
                renderGroupList();
            }
        });
        $('.group-next-page').off('click').on('click', function(){
            let totalPages=Math.ceil(GlobalData.filteredGroups.length/GlobalData.pageSize);
            if(GlobalData.currentPage<totalPages){
                GlobalData.currentPage++;
                renderGroupList();
            }
        });
        $('.group-page-num').off('click').on('click', function(){
            let page=$(this).data('page');
            GlobalData.currentPage=page;
            renderGroupList();
        });
        $('.apple-page-size-select').off('change').on('change', function(){
            GlobalData.pageSize=parseInt($(this).val());
            GlobalData.currentPage=1;
            renderGroupList();
        });
        $('#toggleDebug').off('click').on('click', function(){
            $('#debugPanel').toggle();
        });
        $('#reloadData').off('click').on('click', function(){
            loadData();
        });
        $('#verifyData').off('click').on('click', function(){
            verifyDataWithRetry(function(validation){
                if(validation.isValid){
                    showToast('success', '数据验证通过，共'+validation.totalServerProducts+'个商品');
                }else{
                    showToast('warning', validation.errorMessage || '数据验证失败');
                }
                renderGroupList();
            });
        });
        $('#copyRawJson').off('click').on('click', function(){
            let rawJsonStr=JSON.stringify(GlobalData.rawData, null, 2);
            if(navigator.clipboard){
                navigator.clipboard.writeText(rawJsonStr).then(function(){
                    showToast('success', 'JSON已复制到剪贴板');
                }).catch(function(){
                    fallbackCopy(rawJsonStr);
                });
            }else{
                fallbackCopy(rawJsonStr);
            }
        });
        let fallbackCopy=function(text){
            let textarea=document.createElement('textarea');
            textarea.value=text;
            document.body.appendChild(textarea);
            textarea.select();
            try{
                document.execCommand('copy');
                showToast('success', 'JSON已复制到剪贴板');
            }catch(e){
                showToast('error', '复制失败，请手动复制');
            }
            document.body.removeChild(textarea);
        };
        $('#downloadRawJson').off('click').on('click', function(){
            let rawJsonStr=JSON.stringify(GlobalData.rawData, null, 2);
            let blob=new Blob([rawJsonStr], {type: 'application/json'});
            let url=URL.createObjectURL(blob);
            let a=document.createElement('a');
            a.href=url;
            a.download='upstream_products_'+new Date().toISOString().slice(0,10)+'.json';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
            showToast('success', 'JSON文件已下载');
        });
        $('#toggleRawJson').off('click').on('click', function(){
            $('#rawJsonPreview').toggle();
            $('#rawJsonTruncated').toggle();
        });
        $('#doSearch').off('click').on('click', function(){
            GlobalData.searchKeyword=$('#searchGroup').val();
            GlobalData.searchProductKeyword=$('#searchProduct').val();
            GlobalData.importFilter=$('#importFilter').val();
            GlobalData.currentPage=1;
            renderGroupList();
        });
        $('#resetSearch').off('click').on('click', function(){
            GlobalData.searchKeyword='';
            GlobalData.searchProductKeyword='';
            GlobalData.importFilter='all';
            GlobalData.currentPage=1;
            renderGroupList();
        });
        $('#searchGroup, #searchProduct').off('keypress').on('keypress', function(e){
            if(e.which===13) $('#doSearch').click();
        });
        $('#importFilter').off('change').on('change', function(){
            GlobalData.importFilter=$(this).val();
            GlobalData.currentPage=1;
            renderGroupList();
        });
        $('.group-select').off('change').on('change', function(){
            let val=$(this).val();
            if(val==='-1'){
                let name=prompt('请输入新分组名称:');
                if(name){
                    ajax({
                        data:{action:'save',name:name},
                        success:function(gid){
                            $('.group-select').append('<option value="'+gid+'">'+escapeHtml(name)+'</option>');
                            showToast('success','分组创建成功');
                        }
                    });
                }
            }
        });
        $('.apple-select-wrapper .apple-select-display').off('click').on('click', function(e){
            e.stopPropagation();
            let wrapper=$(this).closest('.apple-select-wrapper');
            $('.apple-select-wrapper').not(wrapper).removeClass('open');
            wrapper.toggleClass('open');
            if(wrapper.hasClass('open')){
                wrapper.find('.apple-select-search input').focus();
                let dropdown=wrapper.find('.apple-select-dropdown');
                let rect=dropdown[0].getBoundingClientRect();
                if(rect.bottom>window.innerHeight){
                    dropdown.css({'top':'auto','bottom':'100%','marginTop':'-2px','marginBottom':'2px'});
                }
                if(rect.right>window.innerWidth){
                    dropdown.css({'left':'auto','right':'0'});
                }
            }
        });
        $('.apple-select-wrapper .apple-select-display').off('keydown').on('keydown', function(e){
            if(e.key==='Enter' || e.key===' '){
                e.preventDefault();
                $(this).click();
            }
        });
        $('.apple-select-wrapper .apple-select-search input').off('input').on('input', function(){
            let keyword=$(this).val().toLowerCase();
            let options=$(this).closest('.apple-select-dropdown').find('.apple-select-options li:not(.create-new)');
            options.each(function(){
                let text=$(this).text().toLowerCase();
                if(text.indexOf(keyword)>-1 || $(this).data('value')==='' || $(this).data('value')==='-1'){
                    $(this).removeClass('hidden');
                }else{
                    $(this).addClass('hidden');
                }
            });
        });
        $('.apple-select-wrapper .apple-select-options li').off('click').on('click', function(e){
            e.stopPropagation();
            let val=$(this).data('value');
            let text=$(this).text();
            let wrapper=$(this).closest('.apple-select-wrapper');
            let display=wrapper.find('.apple-select-display');
            if(val==='-1'){
                wrapper.removeClass('open');
                let name=prompt('请输入新分组名称:');
                if(name){
                    ajax({
                        data:{action:'save',name:name},
                        success:function(gid){
                            GlobalData.GroupsRaw.push({id: gid, name: name});
                            let optionsList=wrapper.find('.apple-select-options');
                            optionsList.append('<li data-value="'+gid+'">'+escapeHtml(name)+'</li>');
                            display.text(name).removeClass('placeholder').data('value', gid);
                            display.removeClass('selected');
                            optionsList.find('li').removeClass('selected');
                            optionsList.find('li[data-value="'+gid+'"]').addClass('selected');
                            showToast('success','分组创建成功');
                        }
                    });
                }
            }else{
                display.text(text).removeClass('placeholder').data('value', val);
                wrapper.find('.apple-select-options li').removeClass('selected');
                $(this).addClass('selected');
                wrapper.removeClass('open');
            }
        });
        $(document).off('click.selectWrapper').on('click.selectWrapper', function(){
            $('.apple-select-wrapper').removeClass('open');
        });
        $('.update-files').off('click').on('click', function(){
            let self=$(this);
            let vid=self.data('vid');
            let id=[];
            let groupWrapper=self.prevAll('.apple-select-wrapper').first();
            let group_id=groupWrapper.find('.apple-select-display').data('value') || '';
            let menu=self.prev('select').val();
            let profit=$('#server-product input[name="profit"]').val();
            let rate=$('#server-product input[name="rate"]').val();
            if(!group_id){
                showToast('warning', "请选择分组");
                return false;
            }
            if(!menu){
                showToast('warning', "请选择导航");
                return false;
            }
            self.closest('.apple-group').find('tbody input[type="checkbox"]:checked').each(function(){
                id.push({id:$(this).val(), name:$(this).data('name')});
            });
            if(id.length<1){
                showToast('warning', "请选择商品");
                return false;
            }
            let fd = new FormData();
            fd.append("upstream_price_value",parseInt(profit)+100);
            fd.append("ptype",menu);
            fd.append("zjmf_finance_api_id",GlobalData.query.id);
            fd.append("rate",rate);
            $.each(id, function(k, v){
                fd.append("productnames["+v.id+"]",v.name);
            });
            let _save=function (gid){
                fd.append("gid",gid);
                Loading.show("导入中...");
                $.ajax({
                    url: './zjmf_finance_api/inputproduct?request_time='+new Date().getTime(),
                    type: "POST",
                    processData: false,
                    contentType: false,
                    data: fd,
                    timeout: 300000,
                    error: function(t, status){
                        Loading.hide();
                        showToast('error', status==='timeout'?"导入超时":"网络错误");
                    },
                    success: function (t) {
                        Loading.hide();
                        if( t.status==200 ){
                            showToast('success', t.msg);
                            setTimeout(function (){
                                let importedIds=id.map(function(item){return String(item.id);});
                                $.each(importedIds, function(i, importedId){
                                    GlobalData.clientProducts[importedId]=true;
                                });
                                let groupIndex=GlobalData.groups.findIndex(function(g){return String(g.id)===String(vid);});
                                if(groupIndex!==-1){
                                    GlobalData.groups[groupIndex].products=GlobalData.groups[groupIndex].products.filter(function(p){
                                        return !importedIds.includes(String(p.id));
                                    });
                                    if(GlobalData.groups[groupIndex].products.length===0){
                                        GlobalData.groups.splice(groupIndex, 1);
                                    }
                                }
                                renderGroupList();
                            }, 300);
                        }else{
                            showToast('error', t.msg);
                        }
                    }
                });
            }
            if(group_id-0>0){
                _save(group_id);
            }else{
                ajax({
                    data:{action:'save',name:self.data('type')},
                    success:function (gid){
                        $('.group-select').append('<option value="'+gid+'">'+self.data('type')+'</option>');
                        _save(gid);
                    }
                });
            }
        });
    }
    let loadData=function(){
        let query=queryToJson();
        GlobalData.query=query;
        Loading.show("加载中...");
        let loadAddpage=function(retryCount){
            retryCount=retryCount||0;
            $.ajax({
                url: './zjmf_finance_api/addpage?request_time=' + new Date().getTime(),
                type: "GET",
                timeout: 120000,
                success: function (addpage) {
                    loadProducts(addpage, 0);
                },
                error: function(xhr, status){
                    if(retryCount<3){
                        showToast('warning', "获取分组失败，重试中("+(retryCount+1)+"/3)");
                        setTimeout(function(){ loadAddpage(retryCount+1); }, 2000);
                    }else{
                        Loading.hide();
                        showToast('error', "获取分组失败，请检查网络连接");
                    }
                }
            });
        };
        let loadProducts=function(addpage, retryCount){
            $.ajax({
                url: './get_upstream_products?id='+query.id+'&languagesys=CN&request_time='+new Date().getTime(),
                type: "GET",
                timeout: 300000,
                success: function (t) {
                    if( t.status==200 ){
                        GlobalData.rawData=t;
                        ajax({
                            data:{action:'check',data:JSON.stringify(t),is_json:1},
                            success:function (r){
                                GlobalData.Groups=[];
                                GlobalData.GroupsRaw=[];
                                GlobalData.Groups.push('<option value="">分组</option>');
                                GlobalData.Groups.push('<option value="-1">+ 新建</option>');
                                if(addpage.data && addpage.data.groupdata){
                                    $.each(addpage.data.groupdata, function(k, v){
                                        GlobalData.Groups.push('<option value="'+escapeHtml(safeId(v.id))+'">'+escapeHtml(safeString(v.name,''))+'</option>');
                                        GlobalData.GroupsRaw.push({id: safeId(v.id), name: safeString(v.name,'')});
                                    });
                                }
                                GlobalData.Menu=[];
                                GlobalData.MenuType={};
                                GlobalData.Menu.push('<option value="">导航</option>');
                                if(addpage.data && addpage.data.ptype){
                                    $.each(addpage.data.ptype, function(k, v){
                                        GlobalData.MenuType[safeString(v.name)]=safeId(v.id);
                                        GlobalData.Menu.push('<option value="'+escapeHtml(safeId(v.id))+'">'+escapeHtml(safeString(v.name,''))+'</option>');
                                    });
                                }
                                let normalizedData=validateAndNormalizeData(r);
                                GlobalData.groups=normalizedData.groups;
                                GlobalData.clientProducts=normalizedData.clientProducts;
                                GlobalData.rate=normalizedData.rate;
                                GlobalData.ProductTypeMap={};
                                if(t && t.product_type && typeof t.product_type==='object'){
                                    GlobalData.ProductTypeMap=t.product_type;
                                }else if(t && t.data && t.data.product_type && typeof t.data.product_type==='object'){
                                    GlobalData.ProductTypeMap=t.data.product_type;
                                }
                                GlobalData.localDomain=normalizedData.localDomain || '';
                                GlobalData.currentPage=1;
                                GlobalData.searchKeyword='';
                                GlobalData.searchProductKeyword='';
                                let validation=validateDataIntegrity(t.data || t, GlobalData.clientProducts);
                                validation.lastCheckTime=new Date().toLocaleString();
                                GlobalData.dataValidation=validation;
                                let rawGroups=0;
                                let rawProducts=0;
                                let serverDataArray=null;
                                if(t && t.data && Array.isArray(t.data)){
                                    serverDataArray=t.data;
                                }else if(t && Array.isArray(t)){
                                    serverDataArray=t;
                                }
                                if(serverDataArray){
                                    rawGroups=serverDataArray.length;
                                    $.each(serverDataArray, function(k, g){
                                        if(g.products && Array.isArray(g.products)){
                                            rawProducts+=g.products.length;
                                        }
                                    });
                                }
                                let processedGroups=GlobalData.groups.length;
                                let processedProducts=0;
                                $.each(GlobalData.groups, function(k, g){
                                    processedProducts+=(g.products || []).length;
                                });
                                Loading.hide();
                                renderGroupList();
                                if(rawGroups!==processedGroups || rawProducts!==processedProducts){
                                    showToast('error', '警告：数据丢失！原始'+rawGroups+'组/'+rawProducts+'商品 → 处理后'+processedGroups+'组/'+processedProducts+'商品，请查看调试面板');
                                }else if(!validation.isValid){
                                    showToast('warning', validation.errorMessage || '数据验证异常');
                                }else{
                                    showToast('success', '加载完成，共'+validation.totalServerProducts+'个商品');
                                }
                            }
                        });
                    }else{
                        Loading.hide();
                        showToast('error', t.msg || "获取上游产品失败");
                    }
                },
                error: function(xhr, status){
                    if(retryCount<3){
                        showToast('warning', "获取产品失败，重试中("+(retryCount+1)+"/3)");
                        setTimeout(function(){ loadProducts(addpage, retryCount+1); }, 2000);
                    }else{
                        Loading.hide();
                        showToast('error', "获取产品失败，请检查网络连接");
                    }
                }
            });
        };
        loadAddpage(0);
    }
    $(function (){
        loadData();
    });
})();
</script>
