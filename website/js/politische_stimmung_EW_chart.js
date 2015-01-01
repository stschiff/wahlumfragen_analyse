function politische_stimmung_EW_chart(svg) {
  var margin = {top: 10, right: 100, bottom: 100, left: 40},
      margin2 = {top: 430, right: 100, bottom: 20, left: 40},
      width = 960 - margin.left - margin.right,
      height = 500 - margin.top - margin.bottom,
      height2 = 500 - margin2.top - margin2.bottom;

  var legendPos = width + 60;

  var parseDate = d3.time.format("%d.%m.%Y").parse;
  var bisectDate = d3.bisector(function(d) { return d.date; }).left;

  var x = d3.time.scale().range([0, width]).domain([parseDate("25.01.2014"), parseDate("31.05.2014")]),
      x2 = d3.time.scale().range([0, width]).domain(x.domain()),
      y = d3.scale.linear().range([height, 0]).domain([0, 50]);

  var partyColors = d3.scale.ordinal()
      .domain(["CDU", "SPD", "GRUENE", "FDP", "LINKE", "AFD"])
      .range(["black", "red", "green", "#FFD300", "pink", "steelblue"]);

  var show = {"CDU":true, "SPD":true, "GRUENE":true, "FDP":true, "LINKE":true, "AFD":true};
  // var election = {"CDU":41.5, "SPD":25.7, "LINKE":8.6, "GRUENE":8.4, "FDP":4.8, "AFD":4.7, "PIRATEN":2.2};
  // var electionDate = "25.5.2014";
  var iOptionList = ["Aus", "Alle", "Emnid", "FgWahlen", "Forsa", "InfratestD", "Insa"];
  var instituteOption = "Alle";
  var correctBias = false;
  var biasData;

  $.ajax({
    url: 'data/params.txt',
    async: false,
    dataType: 'json',
    success: function (data) {
      biasData = {};
      data.institutes.forEach(function(name, i) {
        biasData[name] = {};
        data.parties.forEach(function(party, j) {
          if(party != "SONSTIGE")
            biasData[name][party] = data.biasMatrix[i][j];
        });
      });
    }
  });

  function dateFilter(name, date) {
    if(name == "AFD") {
      return date > parseDate("1.5.2013");
    }
    if(name == "PIRATEN") {
      return date > parseDate("1.9.2011");
    }
    return true;
  } 

  var xAxis = d3.svg.axis().scale(x).orient("bottom"),
      xAxis2 = d3.svg.axis().scale(x2).orient("bottom"),
      yAxis = d3.svg.axis().scale(y).orient("left");

  var area = d3.svg.area()
      .x(function(d) { return x(d.date); })
      .y0(function(d) { return y(d.lower); })
      .y1(function(d) { return y(d.higher); });

  var line = d3.svg.line()
    .x(function(d) {return x(d.date);})
    .y(function(d) {return y(d.mean);});

  svg.attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom);

  svg.append("defs").append("clipPath")
      .attr("id", "clip")
    .append("rect")
      .attr("width", width)
      .attr("height", height);

  var focus = svg.append("g")
      .attr("class", "focus")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
    
  var context = svg.append("g")
      .attr("class", "context")
      .attr("transform", "translate(" + margin2.left + "," + margin2.top + ")");

  var partyData;
  var pollData;


  d3.tsv("data/posterior_Europawahl.txt", function(post_error, raw_data_post) {
    d3.tsv("data/joinedPoll_Europawahl.txt", function(poll_error, raw_data_poll) {
      pollData = partyColors.domain().map(function(name) {
        return {
          name: name,
          values: raw_data_poll.filter(function(d) {return dateFilter(name, parseDate(d.Date));}).map(function(d) {
            return {
              date: parseDate(d.Date),
              val: +d[name],
              institute: d.Institute,
              party: name
            };
          })
        };
      });

      partyData = partyColors.domain().map(function(name) {
        return {
          name: name,
          values: raw_data_post.filter(function(d) {return dateFilter(name, parseDate(d.Date));}).map(function(d) {
            return {
              date: parseDate(d.Date),
              mean: +d[name + "_mean"] * 100,
              lower: +d[name + "_lower"] * 100,
              higher: +d[name + "_higher"] * 100
            };
          })
        };
      });
  
      drawPolls();
      drawPlots();
      // drawElectionMarks();
      drawHoverLine();
      drawLegend();
      drawInstituteLegend();
      drawAxes();
  
    });
  });

  function drawPolls() {
    var plotGroup = focus.append("g");
    var plots = plotGroup.selectAll(".scatterPlot")
      .data(pollData)
      .enter()
      .append("g")
      .attr("class", "scatterPlot")
      .style("fill", function(d) {return partyColors(d.name);})
      .style("display", function(d) {if(show[d.name]) return null; else return "none";});
  
    plots.selectAll(".scatterPoint")
      .data(function(d, i) {return d.values;})
      .enter()
      .append("circle")
      .attr("class", "scatterPoint")
      .attr("cx", function(d) {return x(d.date);})
      .attr("cy", function(d) {
        if(correctBias)
          return y(d.val) - biasData[d.institute][d.party];
        else
          return y(d.val);
      })
      .attr("r", 2);
  }

  function drawPlots() {
    var plotGroup = focus.append("g");
    var plots = plotGroup.selectAll(".plot")
      .data(partyData)
      .enter()
      .append("g")
      .attr("class", "plot")
      .style("display", function(d) {if(show[d.name]) return null; else return "none";});
  
    plots.append("path")
      .attr("class", "areaPlot")
      .style("fill", function(d) { return partyColors(d.name);})
      .attr("d", function(d) {return area(d.values);});

    plots.append("path")
      .attr("class", "linePlot")
      .style("stroke", function(d) { return partyColors(d.name);})
      .attr("d", function(d) {return line(d.values);});
  }

  function drawElectionMarks() {
    var electionGroup = focus.append("g");
    var electionMarks = electionGroup.selectAll(".electionMark")
      .data(partyColors.domain())
      .enter()
      .append("circle")
      .attr("class", "electionMark")
      .style("fill", function(d) { return partyColors(d);})
      .attr("r", 4.0)
      .attr("cx", x(parseDate(electionDate)))
      .attr("cy", function(d) {return y(election[d]);})
      .style("display", function(d) {if(show[d]) return null; else return "none";});
  }

  function drawHoverLine() {
    var hoverLine = focus.append("line")
      .attr("class", "hoverLine")
      .attr("y1", 0)
      .attr("y2", height);

    var hoverTextGroup = focus.append("g")
      .attr("id", "hoverTextGroup");
    hoverTextGroup.append("text")
      .attr("id", "hoverTextDate")
      .attr("x", 20)
      .attr("y", 5);
    hoverTextGroup.selectAll(".hoverTextPartyRange")
      .data(partyData)
      .enter()
      .append("text")
      .attr("class", "hoverTextPartyRange")
      .attr("x", 20)
      .attr("y", function(d, i) {return 5 + 12 * (i + 1);})
      .style("fill", function(d) {return partyColors(d.name)})
      .style("display", function(d) {if(show[d.name]) return null; else return "none";});

    focus.append("rect")
      .attr("class", "overlay")
      .attr("width", width)
      .attr("height", height)
      .on("mouseover", function() {
        hoverLine.style("display", null);
        hoverTextGroup.style("display", null);
      })
      .on("mouseout", function() {
        hoverLine.style("display", "none");
        hoverTextGroup.style("display", "none");
      })
      .on("mousemove", updateHover);
  }

  function updateHover() {
    var x0 = x.invert(d3.mouse(this)[0]);
    var hoverLine = focus.select(".hoverLine");
    var hoverTextGroup = focus.select("#hoverTextGroup");
  
    hoverLine.attr("x1", x(x0)).attr("x2", x(x0));
    hoverTextGroup.select("#hoverTextDate")
      .text(d3.time.format("%d. %b %Y")(x0));
    hoverTextGroup.selectAll(".hoverTextPartyRange")
      .text(function(d, j) {
        i = bisectDate(d.values, x0, 1);
        if(i < 1)
          i = 1;
        if(i >= d.values.length)
          i = d.values.length - 1;
        d0 = d.values[i - 1].date;
        d1 = d.values[i].date;
        i = x0 - d0.date > d1.date - x0 ? i : i - 1;
        return dateFilter(d.name, x0) ? d.name + ": " + Math.round(d.values[i].mean*10)/10 + " [" + Math.round(d.values[i].lower*10)/10 + "-" + Math.round(d.values[i].higher*10)/10 + "]" : "";
      });
  }

  function drawLegend() {
    var legendGroup = focus.append("g");
    var legend = legendGroup.selectAll(".legend")
      .data(partyColors.domain())
      .enter().append("g")
      .attr("class", "legend")
      .attr("transform", function(d, i) { return "translate(0," + i * 20 + ")"; });
  
    legend.append("rect")
      .attr("x", legendPos)
      .attr("width", 18)
      .attr("height", 18)
      .style("stroke", partyColors)
      .style("fill", function(d) {if(show[d]) return partyColors(d); else return "white"})
      .on("click", function(d) { 
        show[d] = !show[d];
        focus.selectAll(".plot")
          .style("display", function(d) {if (show[d.name]) return null; else return "none";});
        focus.selectAll(".scatterPlot")
          .style("display", function(d) {if(instituteOption != "Aus" && show[d.name]) return null; else return "none";});
        legend.selectAll("rect")
          .style("fill", function(d) {if(show[d]) return partyColors(d); else return "white"});
        focus.selectAll(".electionMark")
          .style("display", function(d) {if (show[d]) return null; else return "none";});
        focus.selectAll(".hoverTextPartyRange")
          .style("display", function(d) {if(show[d.name]) return null; else return "none";});
      });

    legend.append("text")
      .attr("x", legendPos - 6)
      .attr("y", 9)
      .attr("dy", ".35em")
      .text(function(d) { return d; });
    
    // correctBiasGroup = legendGroup.append("g")
    //   .attr("class", "legend");
    // correctBiasGroup.append("rect")
    //   .attr("x", legendPos)
    //   .attr("y", 150)
    //   .attr("width", 18)
    //   .attr("height", 18)
    //   .attr("stroke", "black")
    //   .attr("fill", "white");
    
    // correctBiasGroup.select("rect")
    //   .on("click", function() {
    //     correctBias = !correctBias;
    //     focus.selectAll(".scatterPoint")
    //       .transition()
    //       .attr("cy", function(d) {
    //         if(correctBias) {
    //           return y(d.val - biasData[d.institute][d.party]);
    //         }
    //         else {
    //           return y(d.val);
    //         }
    //       });
    //       correctBiasGroup.select("rect")
    //         .attr("fill", function() {if(correctBias)return "black"; else return "white";});
    //   });
    // 
    // correctBiasGroup.append("text")
    //   .attr("x", legendPos - 6)
    //   .attr("y", 159)
    //   .attr("dy", ".35em")
    //   .text("Verschiebung");
      
  }

  function drawInstituteLegend() {
    var iLegendGroup = focus.append("g");
    var iLegend = iLegendGroup.selectAll(".iLegend")
      .data(iOptionList)
      .enter()
      .append("g")
      .attr("class", "iLegend")
      .attr("transform", function(d, i) { return "translate(0," + (200 + i * 30) + ")"; });

    iLegend.append("circle")
      .attr("cx", legendPos + 9)
      .attr("cy", 0)
      .attr("r", 10)
      .style("stroke", "black")
      .style("fill", function(d) {if(d == instituteOption) return "black"; else return "white";})
      .on("click", function(d) {
        if(instituteOption != d) {
          instituteOption = d;
          focus.selectAll(".scatterPlot").style("display", function(dd) {if(instituteOption != "Aus" && show[dd.name]) return null; else return "none";});

          focus.selectAll(".scatterPlot")
            .selectAll(".scatterPoint")
            .attr("fill", function(dd) {
              if(d == "Alle" || dd.institute == d)
                return partyColors(dd.party);
              else
                return "#DDDDDD";
            });

          iLegend.select("circle").style("fill", function(dd) {if(dd == instituteOption) return "black"; else return "white";});
        }
      });
  
    iLegend.append("text")
      .attr("x", legendPos - 6)
      .attr("y", 4)
      .text(function(d) {return d;});
  }

  function drawAxes() {
    focus.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")")
      .call(xAxis);

    focus.append("g")
      .attr("class", "y axis")
      .call(yAxis)
      .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", -40)
      .attr("x", -height+100)
      .attr("dy", ".71em")
      .style("text-anchor", "center")
      .text("Politische Stimmung (%)");

  }
}
