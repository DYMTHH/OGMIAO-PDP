<?php
namespace addons\ojw_sy;

class OjwSyPlugin extends \app\admin\lib\Plugin
{
    public $info = ["name" => "OjwSy", "title" => "OJW一键同步上游", "description" => "橘喵云重构版", "status" => 1, "author" => "OJW", "version" => "1.0", "module" => "addons", "update_description" => "橘喵云重构版", "not_install" => true];
    public function install()
    {
        return true;
    }
    public function uninstall()
    {
        return true;
    }
}

?>