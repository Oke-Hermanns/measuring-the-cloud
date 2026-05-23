library(Cairo)
library(DBI)
library(duckdb)
library(ggplot2)
library(glue)
library(knitr)
library(scales)
library(shades)

sql <- function(query, db = ":memory:") {
  if (!exists("duckdbcons")) {
    duckdbcons <<- new.env()
  }
  if (!exists(db, envir = duckdbcons)) {
    duckdbcons[[db]] <- DBI::dbConnect(
      duckdb::duckdb(dbdir = db, environment_scan = TRUE, read_only = !(db == ":memory:"))
    )
  }
  DBI::dbFetch(DBI::dbSendQuery(duckdbcons[[db]], query))
}

mainfont <- "Garamond"
CairoFonts(
  regular = paste(mainfont, "style=Regular", sep = ":"),
  bold = paste(mainfont, "style=Bold", sep = ":"),
  italic = paste(mainfont, "style=Italic", sep = ":"),
  bolditalic = paste(mainfont, "style=Bold Italic,BoldItalic", sep = ":")
)
pdf <- CairoPDF
png <- CairoPNG
X11.options(type = "cairo")

theme_set(theme_bw(18))

colors <- c(
  "green" = "#a3be8c",
  "dark-green" = as.character(shades::brightness(shades::saturation("#a3be8c", scalefac(5.0)), scalefac(0.80))),
  "purple" = "#b48ead",
  "yellow" = "#ebcb8b",
  "frost" = "#8fbcbb",
  "dark-blue" = "#5e81ac",
  "medium-grey" = "#4c566a",
  "red" = "#bf616a",
  "orange" = "#d08770",
  "light-blue" = "#81a1c1",
  "white-grey" = "#d8dee9",
  "ice" = "#88c0d0",
  "carbon" = "#2e3440"
)

scolors <- sapply(colors, function(x) as.character(shades::saturation(x, scalefac(1.8))))
pcolors <- sapply(scolors, function(x) as.character(shades::brightness(x, scalefac(1.05))))

mkscheme <- function(input_mapping, colors_map = colors) {
  hex_values <- colors_map[unname(input_mapping)]
  setNames(hex_values, names(input_mapping))
}

show_no_data_plot <- function(message) {
  plot.new()
  text(0.5, 0.5, message)
}

placement_levels <- c("co-located-single-az", "different-host-single-az", "multi-az")
placement_labels <- c(
  "co-located-single-az" = "co-located\nsingle-AZ",
  "different-host-single-az" = "different-host\nsingle-AZ",
  "multi-az" = "multi-AZ"
)

base_plot_theme <- function() {
  theme(
    legend.position = "bottom",
    axis.text.x = element_text(angle = 20, hjust = 1),
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )
}
