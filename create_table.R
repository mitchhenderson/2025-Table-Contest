library(tidyverse)
library(gt)
library(gtExtras)

# Setup ---------------------------------------------
colours <- c("#E31937", "#134A8E")
socials <- mitchhenderson::social_caption(icon_colour = "dodgerblue")

# Import --------------------------------------------
raw_data <- read_csv("nrl_simulated_finals_probabilities.csv")

# Transform ----------------------------------------
table_data <- raw_data |>
  mutate(
    perc_no_finals = 1 - percentage,
    total_wins = glue::glue("{total_wins} wins")
  ) |>
  pivot_longer(starts_with("perc"), names_to = "metric", values_to = "perc") |>
  summarise(
    total = total_count[1],
    made_finals = count_made_finals[1],
    list_data = list(perc),
    .by = total_wins
  )

# Create table --------------------------------------
table <- table_data |>
  gt(rowname_col = "total_wins") |>
  gt_theme_538(quiet = TRUE) |>
  fmt_number(columns = c("total", "made_finals"), decimals = 0) |>
  tab_header(
    title = html(
      "National Rugby League teams need to win 13 games or more to be confident of qualifying for the finals"
    ),
    subtitle = "Finals probabilities based on results from 10,000 simulated seasons"
  ) |>
  tab_source_note(
    source_note = html(socials)
  ) |>
  gt_plt_bar_stack(
    list_data,
    width = 70,
    labels = c("Qualify", "Fail to qualify"),
    palette = rev(colours),
    font = "Segoe UI",
    fmt_fn = function(x) {
      case_when(
        x < 0.03 ~ "",
        x == 1 ~ "100%",
        x > 0.999 & x < 1 ~ ">99.9%",
        .default = scales::label_percent(accuracy = 0.1)(x)
      )
    }
  ) |>
  cols_label(
    total = html("Simulated<br>occurrences"),
    made_finals = html("Times<br>qualified")
  ) |>
  cols_label_with(columns = list_data, fn = function(label) {
    full_label <- glue::glue("Finals probability<br>{label}")
    sprintf("<span>%s</span>", full_label) |>
      html()
  }) |>
  tab_style(
    style = cell_text(font = "Myriad Pro"),
    locations = cells_body()
  ) |>
  tab_style(
    style = cell_text(
      font = "Myriad Pro Condensed",
      weight = "bold"
    ),
    locations = cells_title(groups = "title")
  ) |>
  tab_style(
    style = cell_text(align = "right"),
    locations = cells_source_notes()
  ) |>
  tab_options(
    heading.title.font.size = 36,
    heading.subtitle.font.size = 18,
    table.width = 700,
    source_notes.font.size = 15
  )

table

# Save -----------------------------------------------
gtsave(table, "table.html")
