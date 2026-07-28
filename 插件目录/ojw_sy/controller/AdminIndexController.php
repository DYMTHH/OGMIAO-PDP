<?php
namespace addons\ojw_sy\controller;

class AdminIndexController extends \app\admin\controller\PluginAdminBaseController
{
    public $data;
    public $PluginName = "OjwSy";
    public function initialize()
    {
        parent::initialize();
        $this->assign("GzhxPluginPath", $this->uncamelize($this->PluginName));
        $this->data = $_POST;
    }
    public function uncamelize($camelCaps, $separator = "_")
    {
        return strtolower(preg_replace("/([a-z])([A-Z])/", "\$1" . $separator . "\$2", $camelCaps));
    }
    public function success($arr)
    {
        echo json_encode(["status" => 1, "encrypt" => 1, "info" => $arr]);
        exit;
    }
    public function error($arr)
    {
        echo json_encode(["status" => 0, "info" => $arr]);
        exit;
    }
    public function index()
    {
        $List = \Think\Db::name("zjmf_finance_api")->where("hostname", "like", "http%")->select()->toArray();
        $this->assign("Title", "上游列表");
        $this->assign("List", $List);
        return $this->fetch("/index");
    }
    public function curl($url, $method = "get", $params = [], $timeout = 30, $headers = [], $is_json = false)
    {
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, strtoupper($method));
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_HEADER, false);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, $timeout);
        curl_setopt($ch, CURLOPT_FOLLOWLOCATION, 1);
        curl_setopt($ch, CURLINFO_HEADER_OUT, 1);
        if (!empty($headers)) {
            curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        }
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
        if (strtoupper($method) !== "GET") {
            if ($is_json) {
                curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($params));
            } else {
                curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($params));
            }
        }
        $data = curl_exec($ch);
        if ($data) {
            curl_close($ch);
            return $data;
        }
        $error = curl_errno($ch);
        curl_close($ch);
        exit($error);
    }
    public function set()
    {
        if (!empty($this->data)) {
            $action = $this->data["action"];
            if (empty($action)) {
                $action = "";
            }
            switch ($action) {
                case "save":
                    $product_first_groups = \Think\Db::name("product_first_groups")->where("id", "=", 1)->find();
                    if (empty($product_first_groups)) {
                        \Think\Db::name("product_first_groups")->insert(["id" => 1, "name" => "默认分组", "hidden" => 0]);
                    }
                    $gid = \Think\Db::name("product_groups")->insertGetId(["name" => $this->data["name"], "headline" => $this->data["name"], "tagline" => $this->data["name"], "gid" => 1]);
                    $this->success($gid);
                    break;
                case "check":
                    $data = $this->data["data"];
                    if (!empty($this->data["is_json"]) && is_string($data)) {
                        $data = json_decode($data, true);
                    }
                    $productData = [];
                    foreach ($data["data"] as $v) {
                        foreach ($v["products"] as $vv) {
                            $productData[] = $vv["id"];
                        }
                    }
                    if (empty($productData)) {
                        $productData = [0];
                    }
                    $Proucts = \Think\Db::name("products")->field("id,name,upstream_pid,gid")->where("zjmf_api_id", "=", $_GET["id"])->where("upstream_pid", "IN", $productData)->select()->toArray();
                    $Proucts = array_column($Proucts, NULL, "upstream_pid");
                    $upstreamUrl = "";
                    if (!empty($this->data["upstream_url"])) {
                        $upstreamUrl = $this->data["upstream_url"];
                    }
                    $localDomain = "";
                    if (!empty($_SERVER["REQUEST_SCHEME"])) {
                        $localDomain = $_SERVER["REQUEST_SCHEME"] . "://" . $_SERVER["HTTP_HOST"];
                    } else {
                        $localDomain = "http://" . $_SERVER["HTTP_HOST"];
                    }
                    $this->success(["server" => $data, "client" => empty($Proucts) ? ["null"] : $Proucts, "upstream_url" => $upstreamUrl, "local_domain" => $localDomain]);
                    break;
                case "get":
                    $url = parse_url($this->data["uri"]);
                    $uri = $url["scheme"] . "://" . $url["host"] . str_ireplace("/addons", "/get_upstream_products", $url["path"]) . "?" . http_build_query(["id" => $_GET["id"], "request_time" => time(), "languagesys" => "CN"]);
                    $Cookie = [];
                    foreach ($_COOKIE as $k => $v) {
                        $Cookie[] = $k . "=" . $v;
                    }
                    $header = ["User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.131 Safari/537.36 Edg/92.0.902.73", "Cookie: " . implode("; ", $Cookie)];
                    $data = $this->curl($uri, "get", NULL, 30, $header);
                    $data = json_decode($data, true);
                    $productData = [];
                    foreach ($data["data"] as $v) {
                        foreach ($v["products"] as $vv) {
                            $productData[] = $vv["id"];
                        }
                    }
                    if (empty($productData)) {
                        $productData = [0];
                    }
                    $Proucts = \Think\Db::name("products")->field("name,upstream_pid")->where("zjmf_api_id", "=", $_GET["id"])->where("upstream_pid", "IN", $productData)->select()->toArray();
                    $Proucts = array_column($Proucts, NULL, "upstream_pid");
                    $this->success(["server" => $data, "client" => empty($Proucts) ? ["null"] : $Proucts, "addpage" => json_decode($this->curl($url["scheme"] . "://" . $url["host"] . str_ireplace("/addons", "/zjmf_finance_api/addpage", $url["path"]) . "?" . http_build_query(["request_time" => time()]), "get", NULL, 30, $header), true)]);
                    break;
                default:
                    $this->error("参数不存在");
            }
        }
        $upstreamInfo = \Think\Db::name("zjmf_finance_api")->field("hostname")->where("id", "=", $_GET["id"])->find();
        $upstreamUrl = "";
        if (!empty($upstreamInfo["hostname"])) {
            $urlParts = parse_url($upstreamInfo["hostname"]);
            if (!empty($urlParts["scheme"]) && !empty($urlParts["host"])) {
                $upstreamUrl = $urlParts["scheme"] . "://" . $urlParts["host"];
            }
        }
        $this->assign("UpstreamUrl", $upstreamUrl);
        $this->assign("Title", "产品同步");
        return $this->fetch("/set");
    }

}

?>