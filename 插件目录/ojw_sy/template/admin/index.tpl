<link rel="stylesheet" href="/plugins/addons/{$GzhxPluginPath}/template/assets/css/bootstrap-icons.css">
<link rel="stylesheet" href="/plugins/addons/{$GzhxPluginPath}/template/assets/css/bootstrap-scoped.css">
<link rel="stylesheet" href="/plugins/addons/{$GzhxPluginPath}/template/css/bootstrap-ui.css">
<section class="admin-main">
    <div class="apple-container">
        <div class="apple-nav">
            {foreach $PluginsAdminMenu as $v}
                {if $v['custom']}
                    <a href="{$v.url}" target="_blank">{$v.name}</a>
                {else/}
                    <a href="{$v.url}">{$v.name}</a>
                {/if}
            {/foreach}
        </div>
        <div class="apple-section">
            <table class="apple-table">
                <thead>
                    <tr>
                        <th style="width: 100px;">上游ID</th>
                        <th>上游名称</th>
                        <th style="width: 200px;">操作</th>
                    </tr>
                </thead>
                <tbody>
                    {foreach $List as $key=>$item}
                    <tr data-data='{$item|json_encode}'>
                        <td><span class="apple-badge apple-badge-gray">{$item.id}</span></td>
                        <td><strong>{$item.name}</strong></td>
                        <td>
                            <div class="apple-actions">
                                <a href="addons?_plugin={$GzhxPluginPath}&_controller=admin_index&_action=set&id={$item.id}">
                                    </i> 对接
                                </a>
                            </div>
                        </td>
                    </tr>
                    {/foreach}
                </tbody>
            </table>
            {if empty($List)}
            <div class="apple-empty">
                <i class="bi bi-inbox"></i>
                <h4>暂无上游数据</h4>
                <p>请先配置上游接口</p>
            </div>
            {/if}
        </div>
    </div>
</section>
