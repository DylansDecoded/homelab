// Note: Cross-Seed vars should be escaped with $${VAR_NAME} to avoid any interpolation by Flux
module.exports = {
  delay: 20,
  qbittorrentUrl: "http://qbittorrent.default.svc.cluster.local:8080",
  torznab: [
    `http://prowlarr.default.svc.cluster.local:9696/1/api?apikey=$${process.env.PROWLARR_API_KEY}`, // fnp
    `http://prowlarr.default.svc.cluster.local:9696/2/api?apikey=$${process.env.PROWLARR_API_KEY}`, // ipt
    `http://prowlarr.default.svc.cluster.local:9696/3/api?apikey=$${process.env.PROWLARR_API_KEY}`, // milk
    `http://prowlarr.default.svc.cluster.local:9696/8/api?apikey=$${process.env.PROWLARR_API_KEY}`, //ttg
    `http://prowlarr.default.svc.cluster.local:9696/9/api?apikey=$${process.env.PROWLARR_API_KEY}`, //st
    `http://prowlarr.default.svc.cluster.local:9696/11/api?apikey=$${process.env.PROWLARR_API_KEY}` //nzbg,
    `http://prowlarr.default.svc.cluster.local:9696/44/api?apikey=$${process.env.PROWLARR_API_KEY}` //1337x,
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
