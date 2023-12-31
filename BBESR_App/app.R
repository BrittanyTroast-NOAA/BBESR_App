
#BBESR TOOL APP

library(shiny)
library(ggplot2)
library(tidyr)
library(dplyr)
library(plotly)
# library(png)
library(gt)
library(shinythemes)
library(cowplot)
library(gtExtras)  

#####FUNCTIONS#######
#Data used for everything
df_dat_fn<-function(df) {
  df_dat<-df[4:nrow(df),c(1:ncol(df))] 
  
  if (ncol(df_dat)<2.5) {
    colnames(df_dat)<-c("year","value")
    df_dat$value<- as.numeric(df_dat$value)
    
    mean<-mean(as.numeric(df_dat$value), na.rm = T)
    sd<-sd(as.numeric(df_dat$value), na.rm = T)
    
    df_dat$valence[df_dat$value>=mean]<-"pos"
    df_dat$valence[df_dat$value< mean]<-"neg"
    df_dat$min <- ifelse(df_dat$value >= mean, mean, df_dat$value)
    df_dat$max <- ifelse(df_dat$value >= mean, df_dat$value, mean)
    df_dat$year <- as.numeric(df_dat$year)
    df_dat} else {
      
      sub_list<-list() 
      for (i in 2:ncol(df_dat)){
        sub_df<-df_dat[,c(1,i)]
        df_lab<-df[1:3,] #For example sake cutting to only col I need
        ind<-df_lab[3,]
        colnames(sub_df)<-c("year","value")
        # sub_df$value<- as.numeric(sub_df$value)
        sub_df<-as.data.frame(lapply(sub_df, as.numeric))
        
        mean<-mean(as.numeric(sub_df$value), na.rm = T)
        sd<-sd(as.numeric(sub_df$value), na.rm = T)
        
        sub_df$valence[sub_df$value>=mean]<-"pos"
        sub_df$valence[sub_df$value< mean]<-"neg"
        sub_df$min <- ifelse(sub_df$value >= mean, mean, sub_df$value)
        sub_df$max <- ifelse(sub_df$value >= mean, sub_df$value, mean)
        sub_df$year <- as.numeric(sub_df$year)
        sub_df$subnm<-ind[,i]
        sub_list[[i]]<-sub_df
        
      }
      df_dat<-do.call("rbind",sub_list)
    }
  df_dat
  
}

#Pos data set used for main plot
pos_fn<-function(df_dat) {
  if(ncol(df_dat)<6){
    mean<-mean(as.numeric(df_dat$value), na.rm = T)
    sd<-sd(as.numeric(df_dat$value), na.rm = T)
    pos<-df_dat
    pos$value<-ifelse(pos$valence == "pos",pos$value, mean)
    pos} else {
      sub_list<-list()
      subs<-unique(df_dat$subnm)
      for (i in 1:length(subs)){
        sub_df<-df_dat[df_dat$subnm==subs[i],]
        mean<-mean(as.numeric(sub_df$value), na.rm = T)
        sd<-sd(as.numeric(sub_df$value), na.rm = T)
        pos<-sub_df
        pos$value<-ifelse(pos$valence == "pos",pos$value, mean)
        pos$subnm<-subs[i]
        pos$mean<-mean
        pos$sd<-sd
        sub_list[[i]]<-pos
      }
      pos<-do.call("rbind",sub_list)
      pos
    }
}

#Neg data set used for main plot
neg_fn<-function(df_dat) {
  if(ncol(df_dat)<6){
    mean<-mean(as.numeric(df_dat$value), na.rm = T)
    sd<-sd(as.numeric(df_dat$value), na.rm = T)
    neg<-df_dat
    neg$value<-ifelse(neg$valence == "neg",neg$value, mean)
    neg} else {
      sub_list<-list()
      subs<-unique(df_dat$subnm)
      for (i in 1:length(subs)){
        sub_df<-df_dat[df_dat$subnm==subs[i],]
        mean<-mean(as.numeric(sub_df$value), na.rm = T)
        sd<-sd(as.numeric(sub_df$value), na.rm = T)
        neg<-sub_df
        neg$value<-ifelse(neg$valence == "neg",neg$value, mean)
        neg$subnm<-subs[i]
        neg$mean<-mean
        neg$sd<-sd
        sub_list[[i]]<-neg
      }
      neg<-do.call("rbind",sub_list)
      neg
    }
}

#Independent values used throughout
val_fn<-function(df_dat) {
  if(ncol(df_dat)<6){
    mean<-mean(as.numeric(df_dat$value), na.rm = T)
    sd<-sd(as.numeric(df_dat$value), na.rm = T)
    
    #Trend Analysis
    last5<-df_dat[df_dat$year > max(df_dat$year)-5,]
    #Mean Trend
    last5_mean<-mean(last5$value) # mean value last 5 years
    mean_tr<-if_else(last5_mean>mean+sd, "ptPlus", if_else(last5_mean<mean-sd, "ptMinus","ptSolid")) #qualify mean trend
    mean_sym<-if_else(last5_mean>mean+sd, "+", if_else(last5_mean<mean-sd, "-","●")) #qualify mean trend
    mean_word<-if_else(last5_mean>mean+sd, "greater", if_else(last5_mean<mean-sd, "below","within")) #qualify mean trend
    
    #Slope Trend
    lmout<-summary(lm(last5$value~last5$year))
    last5_slope<-coef(lmout)[2,1] * 5 #multiply by years in the trend (slope per year * number of years=rise over 5 years)
    slope_tr<-if_else(last5_slope>sd, "arrowUp", if_else(last5_slope< c(-sd), "arrowDown","arrowRight"))
    slope_sym<-if_else(last5_slope>sd, "↑", if_else(last5_slope< c(-sd), "↓","→"))
    slope_word<-if_else(last5_slope>sd, "an increasing", if_else(last5_slope< c(-sd), "a decreasing","a stable"))
    
    #Dataframe
    vals<-data.frame(mean=mean,
                     sd=sd,
                     mean_tr=mean_tr,
                     slope_tr=slope_tr,
                     mean_sym=mean_sym,
                     slope_sym=slope_sym,
                     mean_word=mean_word,
                     slope_word=slope_word)
    vals} else {
      sub_list<-list()
      subs<-unique(df_dat$subnm)
      for (i in 1:length(subs)){
        sub_df<-df_dat[df_dat$subnm==subs[i],]
        minyear<-min(na.omit(sub_df)$year)
        maxyear<-max(na.omit(sub_df)$year)
        allminyear<-min(df_dat$year)
        allmaxyear<-max(df_dat$year)
        mean<-mean(as.numeric(sub_df$value), na.rm = T)
        sd<-sd(as.numeric(sub_df$value), na.rm = T)
        
        #Trend Analysis
        last5<-sub_df[sub_df$year > max(sub_df$year)-5,]
        #Mean Trend
        last5_mean<-mean(last5$value) # mean value last 5 years
        mean_tr<-if_else(last5_mean>mean+sd, "ptPlus", if_else(last5_mean<mean-sd, "ptMinus","ptSolid")) #qualify mean trend
        mean_sym<-if_else(last5_mean>mean+sd, "+", if_else(last5_mean<mean-sd, "-","●")) #qualify mean trend
        mean_word<-if_else(last5_mean>mean+sd, "greater", if_else(last5_mean<mean-sd, "below","within")) #qualify mean trend
        
        #Slope Trend
        lmout<-summary(lm(last5$value~last5$year))
        last5_slope<-coef(lmout)[2,1] * 5 #multiply by years in the trend (slope per year * number of years=rise over 5 years)
        slope_tr<-if_else(last5_slope>sd, "arrowUp", if_else(last5_slope< c(-sd), "arrowDown","arrowRight"))
        slope_sym<-if_else(last5_slope>sd, "↑", if_else(last5_slope< c(-sd), "↓","→"))
        slope_word<-if_else(last5_slope>sd, "an increasing", if_else(last5_slope< c(-sd), "a decreasing","a stable"))
        
        vals<-data.frame(allminyear=allminyear,
                         allmaxyear=allmaxyear,
                         minyear=minyear,
                         maxyear=maxyear,
                         mean=mean,
                         sd=sd,
                         mean_tr=mean_tr,
                         slope_tr=slope_tr,
                         mean_sym=mean_sym,
                         slope_sym=slope_sym,
                         mean_word=mean_word,
                         slope_word=slope_word,
                         subnm=subs[i])
        
        
        sub_list[[i]]<-vals
      }
      vals<-do.call("rbind",sub_list)
      vals
    }
}

#Main Plot
plot_fn<-function(df_dat, pos, neg, df_lab, val_df) {
  
  
  if (ncol(df_dat)<5.5){
    #single plot
    plot_main<-ggplot(data=df_dat, aes(x=year, y=value))+
      geom_ribbon(data=pos, aes(group=1,ymax=max, ymin=val_df$mean),fill="#7FFF7F")+
      geom_ribbon(data=neg, aes(group=1,ymax=val_df$mean, ymin=min), fill="#FF7F7F")+
      geom_rect(aes(xmin=min(df_dat$year),xmax=max(df_dat$year),ymin=val_df$mean-val_df$sd, ymax=val_df$mean+val_df$sd), fill="white")+
      geom_hline(yintercept=val_df$mean, lty="dashed")+
      geom_hline(yintercept=val_df$mean+val_df$sd)+
      geom_hline(yintercept=val_df$mean-val_df$sd)+
      geom_line(aes(group=1), lwd=1)+
      labs(x="Year", y=df_lab[2,2], title = df_lab[1,2])+
      theme_bw() + theme(title = element_text(size=14, face = "bold"))
    
    if (max(df_dat$year)-min(df_dat$year)>20) {
      plot_main<-plot_main+scale_x_continuous(breaks = seq(min(df_dat$year),max(df_dat$year),5))
    } else {
      plot_main<-plot_main+scale_x_continuous(breaks = seq(min(df_dat$year),max(df_dat$year),2))
    }
    plot_main
    
  } else {
    #facet plot
    
    plot_sec<-ggplot(data=df_dat, aes(x=year, y=value))+
      facet_wrap(~subnm, ncol=1, scales = "free_y")+
      geom_ribbon(data=pos, aes(group=subnm,ymax=max, ymin=mean),fill="#7FFF7F")+
      geom_ribbon(data=neg, aes(group=subnm,ymax=mean, ymin=min), fill="#FF7F7F")+
      geom_rect(data=merge(df_dat,val_df), aes(xmin=allminyear,xmax=allmaxyear,ymin=mean-sd, ymax=mean+sd), fill="white")+
      geom_hline(aes(yintercept=mean), lty="dashed",data=val_df)+
      geom_hline(aes(yintercept=mean+sd),data=val_df)+
      geom_hline(aes(yintercept=mean-sd),data=val_df)+
      geom_line(aes(group=1), lwd=0.75)+
      labs(x="Year", y=df_lab[2,2], title = df_lab[1,2])+
      theme_bw()+theme(strip.background = element_blank(),
                       strip.text = element_text(face="bold"),
                       title = element_text(size=14, face = "bold"))
    
    if (max(df_dat$year)-min(df_dat$year)>20) {
      plot_sec<-plot_sec+scale_x_continuous(breaks = seq(min(df_dat$year),max(df_dat$year),5))
    } else {
      # plot_sec<-plot_sec+scale_x_continuous(breaks = seq(min(df_dat$year),max(df_dat$year),2))
    }
    plot_sec
    
  }
}


#####DATA#####
nav<-read.csv("Data/NAV.csv",header = F)
oilsp<-read.csv("Data/OilSpills.csv", header = F)
drum<-read.csv("Data/Red_Drum.csv", header = F)
blucrabcat<-read.csv("Data/bluecrab_cat.csv", header = F)
brownpeli<-read.csv("Data/brown_peli.csv", header = F)
oystercat<-read.csv("Data/oyster_cat.csv", header = F)
persmallbusi<-read.csv("Data/per_small_busi.csv", header = F)
sstraw<-read.csv("Data/sst_raw.csv", header = F)
vesfish<-read.csv("Data/VesselsFishing_SeafoodDealers.csv", header = F)



#####BASE STUFF#####
testtrend_base<-ggplot(data=data.frame())+
  geom_point()+
  xlim(0,1)+ylim(0,1.1)+ 
  geom_rect(aes(xmin=0, xmax=1, ymin=0.05, ymax=0.55), fill="gray80", color="#4c9be8", linewidth=1)+
  geom_rect(aes(xmin=0, xmax=1, ymin=0.55, ymax=1.05), fill="gray80", color="#4c9be8", linewidth=1)+
  # draw_image(get(tr_an$mean_tr), scale=0.35, y=0.25)+
  # draw_image(get(tr_an$slope_tr), scale=0.35, y=-0.3)+
  annotate(geom="text",label="Mean Trend", x=0.5,y=0.99, size=6, fontface="bold")+
  annotate(geom="text",label="Slope Trend",x=0.5, y=0.45, size=6, fontface="bold")+
  # labs(title = "Last Five Years\nof Data")+
  theme_map()+ theme(plot.title = element_text(size=20, face = "bold", hjust=0.5, color = "#4c9be8"),
                     panel.background = element_blank(),
                     plot.background = element_blank())




# plotly_gg<-ggplotly(plot)


#Need to figure out how to load from GitHUb (loaded locally for now)
# ptPlus<-readPNG("Data/Icons/circlePlus.png")
# ptMinus<-readPNG("Data/Icons/circleMinus.png")
# ptSolid<-readPNG("Data/Icons/circle.png")
# 
# arrowUp<-readPNG("Data/Icons/arrowUp.png")
# arrowDown<-readPNG("Data/Icons/arrowDown.png")
# arrowRight<-readPNG("Data/Icons/arrowRight.png")


#####UI#####
ui <- navbarPage(
  title = "Barataria Basin ESR Tool",
  theme = shinytheme('flatly'),
  
  #Main Page
  tabPanel(
    title= "Explore Indicators",
    
    sidebarLayout(

      sidebarPanel(h1("Data Selection" , style = "font-size:34px;
                                                    text-align: center;"), width = 4,
                   selectInput("data", label = h2("Choose Indicator:", style = "font-size:22px;"), choices = c("Oil Spills","Nuisance Aquatic Vegetation","Red Drum", "Blue Crab Catch","Brown Pelican", "Oyster Catch","Percent Small Business", "Vessels Fishing & Seafood Dealers")),
                   tags$style(".selectize-input {font-size: 18px}"),
                   tags$a(href="https://forms.gle/6ZWFZQuXUnDrfnqn9", "BB ESR Indicator Feedback Form", style="font-size:26px;text-algin=center; margin-top: 50px; margin-left: 25px; text-align: center; font-weight:bold;"),
                   imageOutput("threelogos"), 
                   tags$style("#threelogos {margin-bottom: -200px;
                                              margin-top: 50px;}",
                   ),
      ),
      
      
      #####Main#####
      mainPanel(plotlyOutput("plot", height = "500px"),
                htmlOutput("time_range"),
                tags$style("#time_range {font-size: 20px;
                                            margin-bottom: 0px;
                                            margin-top: -5px;}"),
                gt_output("gt_table"),
                htmlOutput("plain_header"),
                htmlOutput("plain_text"),
                tags$style("#plain_text {font-size:20px;
                                            margin-bottom: 25px;
                                            margin-top: 15px;}"),
                tags$style("#plain_header {font-size:24px;
                                            margin-top: 25px;}"),
                
      )
    )),
  #HowTo
  tabPanel(
    title = "How to Use",
    titlePanel(h1("Instructions", style= "font-size: 34px;
                                            margin-left: 75px;")),
    
    htmlOutput("infotext1"),
    tags$style("#infotext1 {font-size: 20px;
                              margin-left:75px;
                              margin-right: 75px;}"),
    
    imageOutput("plotimg"),
    tags$style("#plotimg {margin-bottom:-200px;
                            margin-top: 25px;
                            text-align: center;
                            width: 250%;}"),
    htmlOutput("infotext2"),
    tags$style("#infotext2 {font-size: 20px;
                              margin-left:75px;
                              margin-right: 75px;}"),
    
    br(),
    "Created with R Shiny",
    
  )
)

#####Server#####
server <- function(input, output) {
  

  
  #####Main plot#####
  output$plot<-renderPlotly({
    df_pick <- switch(input$data, "Nuisance Aquatic Vegetation"=nav,"Oil Spills"=oilsp, "Red Drum"=drum, "Blue Crab Catch"=blucrabcat,"Brown Pelican"=brownpeli, "Oyster Catch"=oystercat,"Percent Small Business"=persmallbusi,"Vessels Fishing & Seafood Dealers"=vesfish)
    df_dat<-df_dat_fn(df_pick)
    pos<-pos_fn(df_dat)
    neg<-neg_fn(df_dat)
    val_df<-val_fn(df_dat)
    df_lab<-df_pick[1:3, c(1:ncol(df_pick))] #For example sake cutting to only col I need
    df_cond<-select(df_dat, -c("valence","min","max"))
    
    plot_main<-plot_fn(df_dat, pos, neg, df_lab, val_df)
    plotly_gg<-ggplotly(plot_main)
    plotly_gg %>%
      rangeslider(start = min(df_cond$year), end = max(df_cond$year))
    
  })
  
  ###View data table###
  output$df_view<-renderTable({
        df_pick <- switch(input$data, "Nuisance Aquatic Vegetation"=nav,"Oil Spills"=oilsp, "Red Drum"=drum, "Blue Crab Catch"=blucrabcat,"Brown Pelican"=brownpeli, "Oyster Catch"=oystercat,"Percent Small Business"=persmallbusi,"Vessels Fishing & Seafood Dealers"=vesfish)
    df_dat<-df_dat_fn(df_pick)
    
    df_dat<-df_dat_fn(df_pick)
    pos<-pos_fn(df_dat)
    neg<-neg_fn(df_dat)
    val_df<-val_fn(df_dat)
    
  })
  
  #####Text Time Selected#####
  output$time_range<- renderText({
        df_pick <- switch(input$data, "Nuisance Aquatic Vegetation"=nav,"Oil Spills"=oilsp, "Red Drum"=drum, "Blue Crab Catch"=blucrabcat,"Brown Pelican"=brownpeli, "Oyster Catch"=oystercat,"Percent Small Business"=persmallbusi,"Vessels Fishing & Seafood Dealers"=vesfish)
    selected_data <- event_data("plotly_relayout")
    df_dat<-df_dat_fn(df_pick)
    sel_dat<-df_dat[df_dat$year>selected_data$xaxis.range[1] & df_dat$year< selected_data$xaxis.range[2],]
    
    if (nrow(sel_dat)>0) {
      range<-range(sel_dat$year)
      paste0("<b>Time Frame=",range[1],"-",range[2],"</b>")
    } else  {
      range<-range(df_dat$year)
      paste0("<b>Time Frame=",range[1],"-",range[2],"</b>")
    }
    
    
  })
  
  #####Table#####
  output$gt_table<- render_gt({
        df_pick <- switch(input$data, "Nuisance Aquatic Vegetation"=nav,"Oil Spills"=oilsp, "Red Drum"=drum, "Blue Crab Catch"=blucrabcat,"Brown Pelican"=brownpeli, "Oyster Catch"=oystercat,"Percent Small Business"=persmallbusi,"Vessels Fishing & Seafood Dealers"=vesfish)
    selected_data <- event_data("plotly_relayout")
    df_dat<-df_dat_fn(df_pick)
    val_df<-val_fn(df_dat)
    
    sel_dat<-df_dat[df_dat$year>selected_data$xaxis.range[1] & df_dat$year< selected_data$xaxis.range[2],]
    
    if (nrow(sel_dat)>3) {
      if (ncol(df_dat)<5.5) {
        #Mean Trend
        sel_dat_mean<-mean(sel_dat$value) # mean value last 5 years
        mean_sel<-if_else(sel_dat_mean>val_df$mean+val_df$sd, "+", if_else(sel_dat_mean<val_df$mean-val_df$sd, "-","●")) #qualify mean trend
        
        #Slope Trend
        lmout<-summary(lm(sel_dat$value~sel_dat$year))
        sel_slope<-coef(lmout)[2,1] * length(unique(sel_dat$year)) #multiply by years in the trend (slope per year * number of years=rise over 5 years)
        slope_sel<-if_else(sel_slope>val_df$sd, "↑", if_else(sel_slope< c(-val_df$sd), "↓","→"))
        
        ###Table stuff
        new_table<-data.frame(val=c(round(val_df$mean,2), round(val_df$sd,2), val_df$mean_sym, val_df$slope_sym, mean_sel, slope_sel),
                              metric=c("Historical_Mean","Historical_SD","Last 5_Mean", "Last 5_Slope","Selected_Mean", "Selected_Slope"))
        
        new_table <- new_table %>% pivot_wider(names_from = metric, values_from = val)
        
        gt(new_table) %>%
          tab_spanner_delim(delim = "_") %>%
          tab_stubhead(label = "Sub Indicator") %>% 
          tab_header(title = "Trends in Mean & Slope") %>%
          tab_options(table.border.top.color = "#3498db",
                      table.border.bottom.color = "#3498db",
                      table.border.left.color = "#3498db",
                      table.border.right.color = "#3498db",
                      table.border.top.width = 5,
                      table.border.bottom.width = 5,
                      table.border.left.width = 5,
                      table.border.right.width = 5,
                      table.border.left.style = "solid",
                      table.border.right.style = "solid",) %>%
          tab_style(style = cell_text(align = "center", size=px(18)),locations = cells_body()) %>%
          tab_style(style = cell_text(align = "center", size=px(20), weight = "bold", color="#2c3e50"),locations = cells_stubhead()) %>%
          tab_style(style = cell_text(align = "center", size=px(18), weight = "bold", color="#2c3e50"),locations = cells_stub()) %>%
          tab_style(style = cell_text(align = "center", size=px(18)),locations = cells_column_labels()) %>%
          tab_style(style = cell_text(align = "center", size=px(20), weight = "bold", color="#2c3e50"),locations = cells_column_spanners()) %>%
          tab_style(style = cell_text(align = "center", size=px(24), color="#3498db", weight = "bold"),locations = cells_title())
      } else {
        #Selected Multi Sub
        
        sub_list<-list()
        subs<-unique(df_dat$subnm)
        for (i in 1:length(subs)){
          sub_df<-sel_dat[sel_dat$subnm==subs[i],]
          vals<-val_df[val_df$subnm==subs[i],]
          sub_dat_mean<-mean(sub_df$value) # mean value last 5 years
          mean_sub<-if_else(sub_dat_mean>vals$mean+vals$sd, "+", if_else(sub_dat_mean<vals$mean-vals$sd, "-","●")) #qualify mean trend
          
          #Slope Trend
          lmout<-summary(lm(sub_df$value~sub_df$year))
          sub_slope<-coef(lmout)[2,1] * length(unique(sub_df$year)) #multiply by years in the trend (slope per year * number of years=rise over 5 years)
          slope_sub<-if_else(sub_slope>vals$sd, "↑", if_else(sub_slope< c(-vals$sd), "↓","→"))
          
          add_sub<-data.frame(mean_sel=mean_sub,
                              slope_sel=slope_sub)
          sub_list[[i]]<-add_sub
          
        }
        
        add_sel_df<-do.call("rbind",sub_list)
        val_df<-cbind(val_df, add_sel_df)
        
        val_df$mean<-as.character(val_df$mean)
        val_df$sd<-as.character(val_df$sd)
        
        new_table<-val_df %>% select("Sub_Indicator"=subnm,"Historical_Mean"=mean, "Historical_SD"=sd, "Last 5_Mean"=mean_sym, "Last 5_Slope"=slope_sym, "Selected_Mean"=mean_sel, "Selected_Slope"=slope_sel) %>% 
          group_by(Sub_Indicator) %>% pivot_longer(cols = -c("Sub_Indicator"))
        
        
        new_table <- new_table %>% pivot_wider(names_from = name, values_from = value)
        new_table[,2:3]<-lapply(new_table[,2:3], function(x) {round(as.numeric(x),2)})
        rownames(new_table)<-new_table$Sub_Indicator
        
        gt(new_table, rowname_col = "Sub_Indicator", groupname_col = NA) %>%
          tab_spanner_delim(delim = "_") %>%
          tab_stubhead(label = "Sub Indicator") %>% 
          tab_header(title = "Trends in Mean & Slope") %>%
          tab_options(table.border.top.color = "#3498db",
                      table.border.bottom.color = "#3498db",
                      table.border.left.color = "#3498db",
                      table.border.right.color = "#3498db",
                      table.border.top.width = 5,
                      table.border.bottom.width = 5,
                      table.border.left.width = 5,
                      table.border.right.width = 5,
                      table.border.left.style = "solid",
                      table.border.right.style = "solid",) %>%
          tab_style(style = cell_text(align = "center", size=px(18)),locations = cells_body()) %>%
          tab_style(style = cell_text(align = "center", size=px(20), weight = "bold", color="#2c3e50"),locations = cells_stubhead()) %>%
          tab_style(style = cell_text(align = "center", size=px(18), weight = "bold", color="#2c3e50"),locations = cells_stub()) %>%
          tab_style(style = cell_text(align = "center", size=px(18)),locations = cells_column_labels()) %>%
          tab_style(style = cell_text(align = "center", size=px(20), weight = "bold", color="#2c3e50"),locations = cells_column_spanners()) %>%
          tab_style(style = cell_text(align = "center", size=px(24), color="#3498db", weight = "bold"),locations = cells_title())
      }
      
      
    } else {
      
      ###Table stuff
      if (ncol(df_dat)<5.5) {
        new_table<-data.frame(val=c(round(val_df$mean,2), round(val_df$sd,2), val_df$mean_sym, val_df$slope_sym),
                              metric=c("Historical_Mean","Historical_SD","Last 5_Mean", "Last 5_Slope"))
        
        new_table <- new_table %>% pivot_wider(names_from = metric, values_from = val)
        
        gt(new_table) %>%
          tab_spanner_delim(delim = "_") %>%
          tab_stubhead(label = "Sub Indicator") %>% 
          tab_header(title = "Trends in Mean & Slope") %>%
          tab_options(table.border.top.color = "#3498db",
                      table.border.bottom.color = "#3498db",
                      table.border.left.color = "#3498db",
                      table.border.right.color = "#3498db",
                      table.border.top.width = 5,
                      table.border.bottom.width = 5,
                      table.border.left.width = 5,
                      table.border.right.width = 5,
                      table.border.left.style = "solid",
                      table.border.right.style = "solid",) %>%
          tab_style(style = cell_text(align = "center", size=px(18)),locations = cells_body()) %>%
          tab_style(style = cell_text(align = "center", size=px(20), weight = "bold", color="#2c3e50"),locations = cells_stubhead()) %>%
          tab_style(style = cell_text(align = "center", size=px(18), weight = "bold", color="#2c3e50"),locations = cells_stub()) %>%
          tab_style(style = cell_text(align = "center", size=px(18)),locations = cells_column_labels()) %>%
          tab_style(style = cell_text(align = "center", size=px(20), weight = "bold", color="#2c3e50"),locations = cells_column_spanners()) %>%
          tab_style(style = cell_text(align = "center", size=px(24), color="#3498db", weight = "bold"),locations = cells_title())
        
      } else {
        val_df$mean<-as.character(val_df$mean)
        val_df$sd<-as.character(val_df$sd)
        
        new_table<-val_df %>% select("Sub_Indicator"=subnm,"Historical_Mean"=mean, "Historical_SD"=sd, "Last 5_Mean"=mean_sym, "Last 5_Slope"=slope_sym) %>% 
          group_by(Sub_Indicator) %>% pivot_longer(cols = -c("Sub_Indicator"))
        
        
        new_table <- new_table %>% pivot_wider(names_from = name, values_from = value)
        new_table[,2:3]<-lapply(new_table[,2:3], function(x) {round(as.numeric(x),2)})
        rownames(new_table)<-new_table$Sub_Indicator
        
        gt(new_table, rowname_col = "Sub_Indicator", groupname_col = NA) %>%
          tab_spanner_delim(delim = "_") %>%
          tab_stubhead(label = "Sub Indicator") %>% 
          tab_header(title = "Trends in Mean & Slope") %>%
          tab_options(table.border.top.color = "#3498db",
                      table.border.bottom.color = "#3498db",
                      table.border.left.color = "#3498db",
                      table.border.right.color = "#3498db",
                      table.border.top.width = 5,
                      table.border.bottom.width = 5,
                      table.border.left.width = 5,
                      table.border.right.width = 5,
                      table.border.left.style = "solid",
                      table.border.right.style = "solid",) %>%
          tab_style(style = cell_text(align = "center", size=px(18)),locations = cells_body()) %>%
          tab_style(style = cell_text(align = "center", size=px(20), weight = "bold", color="#2c3e50"),locations = cells_stubhead()) %>%
          tab_style(style = cell_text(align = "center", size=px(18), weight = "bold", color="#2c3e50"),locations = cells_stub()) %>%
          tab_style(style = cell_text(align = "center", size=px(18)),locations = cells_column_labels()) %>%
          tab_style(style = cell_text(align = "center", size=px(20), weight = "bold", color="#2c3e50"),locations = cells_column_spanners()) %>%
          tab_style(style = cell_text(align = "center", size=px(24), color="#3498db", weight = "bold"),locations = cells_title())
        
        
        
        
        
        
        
      }
      
    }
  })
  
  #####Sel Trend Plot#####
  output$trend_plot<- renderPlot({
        df_pick <- switch(input$data, "Nuisance Aquatic Vegetation"=nav,"Oil Spills"=oilsp, "Red Drum"=drum, "Blue Crab Catch"=blucrabcat,"Brown Pelican"=brownpeli, "Oyster Catch"=oystercat,"Percent Small Business"=persmallbusi,"Vessels Fishing & Seafood Dealers"=vesfish)
    df_dat<-df_dat_fn(df_pick)
    val_df<-val_df(df_dat)
    selected_data <- event_data("plotly_relayout")
    sel_dat<-df_dat[df_dat$year>selected_data$xaxis.range[1] & df_dat$year< selected_data$xaxis.range[2],]
    
    
    if(nrow(sel_dat)>3) {
      
      #Mean Trend
      sel_dat_mean<-mean(sel_dat$value) # mean value last 5 years
      mean_tr_sel<-if_else(sel_dat_mean>val_df$mean+val_df$sd, "ptPlus", if_else(sel_dat_mean<val_df$mean-val_df$sd, "ptMinus","ptSolid")) #qualify mean trend
      
      #Slope Trend
      lmout<-summary(lm(sel_dat$value~sel_dat$year))
      sel_slope<-coef(lmout)[2,1] * length(unique(sel_dat$year)) #multiply by years in the trend (slope per year * number of years=rise over 5 years)
      slope_tr_sel<-if_else(sel_slope>val_df$sd, "arrowUp", if_else(sel_slope< c(-val_df$sd), "arrowDown","arrowRight"))
      
      range<-range(sel_dat$year)
      
      plot_trend<-testtrend_base+
        draw_image(get(mean_tr_sel), scale=0.35, y=0.25)+
        draw_image(get(slope_tr_sel), scale=0.35, y=-0.3)+
        labs(title = paste0("Selected Years\n(",range[1],"-",range[2],")"))
      
      plot_trend
    }
    
  }, bg="transparent")
  
  #####Last5 Trend Plot#####
  output$trendplot_last5<- renderPlot({
        df_pick <- switch(input$data, "Nuisance Aquatic Vegetation"=nav,"Oil Spills"=oilsp, "Red Drum"=drum, "Blue Crab Catch"=blucrabcat,"Brown Pelican"=brownpeli, "Oyster Catch"=oystercat,"Percent Small Business"=persmallbusi,"Vessels Fishing & Seafood Dealers"=vesfish)
    df_dat<-df_dat_fn(df_pick)
    val_df<-val_fn(df_dat)
    
    testtrend_base+
      draw_image(get(val_df$mean_tr), scale=0.35, y=0.25)+
      draw_image(get(val_df$slope_tr), scale=0.35, y=-0.3)+
      labs(title = "Last Five Years\nof Data")
    
  }, bg="transparent")
  
  #####Plain Text#####
  output$plain_header<- renderText({
    plain_header<-paste0("<b><u>Summary</b></u>")
  })
  
  output$plain_text<-renderText({
        df_pick <- switch(input$data, "Nuisance Aquatic Vegetation"=nav,"Oil Spills"=oilsp, "Red Drum"=drum, "Blue Crab Catch"=blucrabcat,"Brown Pelican"=brownpeli, "Oyster Catch"=oystercat,"Percent Small Business"=persmallbusi,"Vessels Fishing & Seafood Dealers"=vesfish)
    df_dat<-df_dat_fn(df_pick)
    df_lab<-df_pick[1:3, c(1:ncol(df_pick))] #For example sake cutting to only col I need
    val_df<-val_fn(df_dat)
    selected_data <- event_data("plotly_relayout")
    sel_dat<-df_dat[df_dat$year>selected_data$xaxis.range[1] & df_dat$year< selected_data$xaxis.range[2],]
    
    if (nrow(sel_dat)<3) {
      ###Not selected no subs
      if (ncol(df_dat)<5.5) {
        text<-paste0("The <b>",df_lab[1,2] ,"</b> indicator has a historical mean of <u><b>", round(val_df$mean[1],2),"</u></b> ±<u><b>",round(val_df$sd[1],2)  ,"</u></b> and trends for the last five years of data show mean values <b><u>",val_df$mean_word, "</b></u> 1 standard deviation from the historical mean and <u><b>",val_df$slope_word, "</u></b> trend in slope.")
      } else {
        ###Not slected subs
        val_df$mean<-as.character(val_df$mean)
        val_df$sd<-as.character(val_df$sd)
        
        new_table<-val_df %>% select(subnm, mean,  sd,  mean_sym,  slope_sym) %>% 
          group_by(subnm) %>% pivot_longer(cols = -c(subnm))
        
        val_df$mean<-as.numeric(val_df$mean)
        val_df$sd<-as.numeric(val_df$sd)
        
        
        text<-paste0("The <b>",df_lab[1,2] ,"</b> indicator for the <u><b>", val_df$subnm[1],"</u></b> sub indicator has a historical mean of <u><b>", round(val_df$mean[1],2),"</u></b> ±<u><b>",round(val_df$sd[1],2)  ,"</u></b> and trends for the last five years of data show mean values <b><u>",val_df$mean_word[1], "</b></u> 1 standard deviation from the historical mean and <u><b>",val_df$slope_word[1], "</u></b> trend in slope.")
        
        text_li<-list()
        for (i in 2:length(val_df$subnm)) {
          subtext<-paste0("The <u><b>",val_df$subnm[i], "</u></b> sub index historical mean is <u><b>",round(val_df$mean[i],2),"</u></b>±<u><b>",round(val_df$sd[i],2),"</u></b> and trends from the last five years of data show mean values<u><b>",val_df$mean_word[i],"</u></b> 1 standard deviation from the historical mean and <u><b>",val_df$slope_word[i], "</u></b> trend in slope.") 
          text_li[[i]]<-subtext
        }
        subs_text<-do.call("paste", text_li)
        paste(text,subs_text)
      }
      
      
    } else {
      if (ncol(df_dat)<5.5) {
        
        #Selected no subs
        #Mean Trend
        sel_dat_mean<-mean(sel_dat$value) # mean value last 5 years
        mean_sel_word<-if_else(sel_dat_mean>val_df$mean+val_df$sd, "greater", if_else(sel_dat_mean<val_df$mean-val_df$sd, "below","within")) #qualify mean trend
        
        #Slope Trend
        lmout<-summary(lm(sel_dat$value~sel_dat$year))
        sel_slope<-coef(lmout)[2,1] * length(unique(sel_dat$year)) #multiply by years in the trend (slope per year * number of years=rise over 5 years)
        slope_sel_word<-if_else(sel_slope>val_df$sd, "an increasing", if_else(sel_slope< c(-val_df$sd), "a decreasing","a stable"))
        
        range<-range(sel_dat$year)
        
        text<-paste0("The <b>",df_lab[1,2] ,"</b> indicator has a historical mean of <u><b>", round(val_df$mean[1],2),"</u></b> ±<u><b>",round(val_df$sd[1],2)  ,"</u></b> and trends for the last five years of data show mean values <b><u>",val_df$mean_word, "</u></b> 1 standard deviation from the historical mean and <b><u>",val_df$slope_word, "</b></u> trend in slope. The trends in the selected years of data <b>(",range[1],"-",range[2],")</b> show mean values <b><u>", mean_sel_word,"</b></u> 1 standard deviation from the historical mean and <b><u>",slope_sel_word, "</b></u> trend in slope.")
        
        
      } else {
        ###Selected w subs
        sub_list<-list()
        subs<-unique(df_dat$subnm)
        for (i in 1:length(subs)){
          sub_df<-sel_dat[sel_dat$subnm==subs[i],]
          vals<-val_df[val_df$subnm==subs[i],]
          sub_dat_mean<-mean(sub_df$value) # mean value last 5 years
          mean_sub<-if_else(sub_dat_mean>vals$mean+vals$sd, "greater", if_else(sub_dat_mean<vals$mean-vals$sd, "below","within")) #qualify mean trend
          
          #Slope Trend
          lmout<-summary(lm(sub_df$value~sub_df$year))
          sub_slope<-coef(lmout)[2,1] * length(unique(sub_df$year)) #multiply by years in the trend (slope per year * number of years=rise over 5 years)
          slope_sub<-if_else(sub_slope>vals$sd, "an increasing", if_else(sub_slope< c(-vals$sd), "a decreasing","a stable"))
          
          add_sub<-data.frame(mean_sel=mean_sub,
                              slope_sel=slope_sub)
          sub_list[[i]]<-add_sub
          
        }
        add_sel_df<-do.call("rbind",sub_list)
        val_df<-cbind(val_df, add_sel_df)
        
        val_df$mean<-as.character(val_df$mean)
        val_df$sd<-as.character(val_df$sd)
        
        val_df<-val_df %>% select(subnm,mean, sd, mean_word, slope_word, mean_sel, slope_sel)
        val_df$mean<-as.numeric(val_df$mean)
        val_df$sd<-as.numeric(val_df$sd)
        
        range<-range(sel_dat$year)
        
        text<-paste0("The <b>",df_lab[1,2] ,"</b> indicator for the <u><b>", val_df$subnm[1],"</u></b> sub indicator has a historical mean of <u><b>", round(val_df$mean[1],2),"</u></b> ±<u><b>",round(val_df$sd[1],2)  ,"</u></b> and trends for the last five years of data show mean values <b><u>",val_df$mean_word[1], "</b></u> 1 standard deviation from the historical mean and <u><b>",val_df$slope_word[1], "</u></b> trend in slope. The trends in the selected years of data <b>(",range[1],"-",range[2],")</b> show mean values <b><u>", val_df$mean_sel[1],"</b></u> 1 standard deviation from the historical mean and <b><u>",val_df$slope_sel[1], "</b></u> trend in slope.")
        
        text_li<-list()
        for (i in 2:length(val_df$subnm)) {
          subtext<-paste0("The <u><b>",val_df$subnm[i], "</u></b> sub index historical mean is <u><b>",round(val_df$mean[i],2)," </u></b>±<u><b>",round(val_df$sd[i],2),"</u></b> and trends from the last five years of data show mean values <u><b>",val_df$mean_word[i],"</u></b> 1 standard deviation from the historical mean and <u><b>",val_df$slope_word[i], "</u></b> trend in slope. The trends in the selected years of data show mean values <b><u>", val_df$mean_sel[i],"</b></u> 1 standard deviation from the historical mean and <b><u>",val_df$slope_sel[i], "</b></u> trend in slope.") 
          text_li[[i]]<-subtext
        }
        subs_text<-do.call("paste", text_li)
        paste(text,subs_text)
        
      }
      
      
    }
  })
  
  #####Add Images#####
  output$threelogos<-renderImage({
    list(src = "WWW/Three Logos.png",
         contentType = "image/png",
         align="bottom",
         width="100%") }, deleteFile=F)
  
  #####STUFF FOR INFO PAGE#####
  #Help fig
  output$plotimg<-renderImage({
    list(src="WWW/TS_info.png",
         contentType="image/png",
         align="center")
  }, deleteFile = F)
  
  #Text
  output$introtext<-renderText({
    
    introtext<-"This app is intended to provide a way to interact with indicators from the Barataria Basin Ecosystem Status Report (ESR). The Barataria Basin ESR is a report with over 100 indicators describing drivers, pressures, states, human activities, and human dimensions produced by NOAA's Integrated Ecosystem Assessment (IEA) program. This is a prototype app with a small selection of indicators in order to get feedback for a potential future product."
  })
  
  output$usehead<-renderText({
    
    infotext<-"How to Use"
  })
  
  output$infotext1<-renderText({
    
    infotext1<-"<b>1.</b> Begin by choosing the indicator from the dropdown menu on the left of the screen. <br><br>
      <b>2</b>. The indicator time series plot will be updated on the right. Below is a figure on how to interpret the plot."
  })
  
  output$infotext2<-renderText({
    
    infotext2<-"<b>3.</b> Below the plot is a rangeslider. Pull on either end of the slider to customize the time range of the plot. The time frame you have chosen will appear in text below the slider, originally indicating the full time frame of the indicator. <br><br>
      <b>4.</b> A table below the figure show the historical mean and standard deviation (presented as dashed and solid black horizontal lines) and the trends in mean and slope compared to those values of the last five years of data as presented in the ESR. This table will update with trends of mean and slope if a custom time frame is selected using the rangeslider. <br><br>
      <b>5.</b> Below the table is a plain text summary of the table above, describing mean and SD values as well as trends in mean and slope for the last five years of data and slected time frames." 
  })
  
}



# Run the application 
app<-shinyApp(ui = ui, server = server)

runApp(app)
