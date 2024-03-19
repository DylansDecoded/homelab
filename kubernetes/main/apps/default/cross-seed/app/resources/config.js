// Note: Cross-Seed vars should be escaped with $${VAR_NAME} to avoid any interpolation by Flux
module.exports = {
  delay: 20,
  qbittorrentUrl: "http://qbittorrent.default.svc.cluster.local:8080",
  torznab: [
    `http://prowlarr.default.svc.cluster.local:9696/1/api?apikey=$${process.env.PROWLARR_API_KEY}`, // fnp
    `http://prowlarr.default.svc.cluster.local:9696/2/api?apikey=$${process.env.PROWLARR_API_KEY}`, // ipt
    `http://prowlarr.default.svc.cluster.local:9696/3/api?apikey=$${process.env.PROWLARR_API_KEY}`, // milk
    `http://prowlarr.default.svc.cluster.local:9696/4/api?apikey=$${process.env.PROWLARR_API_KEY}`, //1337x
    `http://prowlarr.default.svc.cluster.local:9696/5/api?apikey=$${process.env.PROWLARR_API_KEY}`, // kbn
    `http://prowlarr.default.svc.cluster.local:9696/6/api?apikey=$${process.env.PROWLARR_API_KEY}`, // ia
    `http://prowlarr.default.svc.cluster.local:9696/7/api?apikey=$${process.env.PROWLARR_API_KEY}` //rarbg
  ],
  port: process.env.CROSSSEED_PORT || 80,
  apiAuth: false,
  action: "inject",
  includeEpisodes: false,
  includeSingleEpisodes: true,
  includeNonVideos: true,
  duplicateCategories: true,
  matchMode: "safe",
  skipRecheck: true,
  outputDir: "/config",
  torrentDir: "/qbittorrent/qBittorrent/BT_backup",
};
