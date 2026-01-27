/*****************************************************
 * Projet : Okovision - Supervision chaudiere OeKofen
 * Auteur : Stawen Dronek
 * Utilisation commerciale interdite sans mon accord
 ******************************************************/
/* global lang, Highcharts, $ */
if (!String.prototype.format) {
    String.prototype.format = function () {
        var args = arguments;
        return this.replace(/\{(\d+)\}/g, function (m, n) {
            return args[n];
        });
    };
}

$(document).ready(function() {


	function graphe_error(where, titre) {
		var chart = new Highcharts.Chart({
			chart: {
				renderTo: where,
				type: 'line'
			},
			title: {
				text: titre
			},
			subtitle: {
				text: lang.error.communication
			}
		});

	}

	function DecSepa(s) {
		return s.replace(".", ",");
	}

	function generer_graphic() {

		var titre_histo = lang.text.titreHisto;
		var div_histo_tempe = 'histo-temperature';

		$.api('GET', 'rendu.getHistoByMonth', {
				month: $("#mois").val(),
				year: $("#annee").val()
			}).done(function(json) {
				//Personnalisation des données
				//T°C max
				json[0].color = "red";
				json[0].zIndex = 3;
				//T°C min
				json[1].color = "blue";
				json[1].zIndex = 2;
				//Consommation Pellet Kg			
				json[2].type = "column";
				json[2].zIndex = 1;
				json[2].yAxis = 1;

				json[2].dataLabels = {
					enabled: true,
					rotation: -90,
					color: '#FFFFFF',
					align: 'right',
					x: 3,
					y: 10,
					style: {
						fontSize: '10px',
						fontFamily: 'Verdana, sans-serif',
						textShadow: '0 0 5px black'
					}
				}

				//DJU
				//json[3].type = "column";
				//json[3].color = "#D1CFCB";
				json[3].color = "gray";
				json[3].zIndex = 4;
				json[3].yAxis = 1;

				//nb cycle
				json[4].type = "column";
				json[4].color = "#ECB962";
				json[4].yAxis = 2;

				json[4].dataLabels = {
					enabled: true,
					rotation: -90,
					//color: '#FFFFFF',
					align: 'right',
					x: 3,
					verticalAlign: 'bottom',
					style: {
						fontSize: '10px',
						fontFamily: 'Verdana, sans-serif' //,
							//textShadow: '0 0 5px black'
					}
				}

				var chart = new Highcharts.Chart({
					chart: {
						renderTo: div_histo_tempe,
						type: 'spline' //,
							//zoomType: 'x',
							//panning: true,
							//panKey: 'shift'
					},
					title: {
						text: titre_histo
					} /*,
					legend: {
						align: 'right',
						verticalAlign: 'middle',
						layout: 'vertical'
					}*/,
					xAxis: {
						categories: ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10',
							'11', '12', '13', '14', '15', '16', '17', '18', '19', '20',
							'21', '22', '23', '24', '25', '26', '27', '28', '29', '30',
							'31'
						],
						max: 30,
						title: {
							text: lang.graphic.day,
						}
					},
					yAxis: [{
						title: {
							text: lang.graphic.tc
						},
						min: -5,
						max: 40
					}, {
						gridLineWidth: 0,
						title: {
							text: lang.graphic.kgAndDju,
							style: {
								color: Highcharts.getOptions().colors[4]
							}
						},
						min: 0,
						max: 60,
						opposite: true
					}, {
						gridLineWidth: 0,
						title: {
							text: lang.graphic.nbCycle,
							style: {
								color: "#ECB962"
							}
						},
						min: 0,
						max: 50,
						opposite: true
					}],
					plotOptions: {
						line: {
							marker: {
								enabled: true
							}
						},
						column: {
							pointPadding: 0,
							borderWidth: 0.2
						}
					},
					series: json
				}, function(chart) {

					var bottom = chart.plotHeight - 20;

					$.each(chart.series[4].data, function(i, data) {

						data.dataLabel.attr({
							y: bottom
						});
					});

				});


			})
			.error(function() {
				graphe_error(div_histo_tempe, titre_histo);
				//$.growlErreur("Probleme lors de la recuperation de la synthese du mois");
			});

		/*
		 * Gestion des indicateurs du mois 
		 */
		$.api('GET', 'rendu.getIndicByMonth', {
				month: $("#mois").val(),
				year: $("#annee").val()
			}).done(function(json) {

				$("#tcmax").text(DecSepa(json.tcExtMax + " °C"));
				$("#tcmin").text(DecSepa(json.tcExtMin + " °C"));
				$("#tcmoy").text(DecSepa(((json.tcExtMoy === null) ? 0.0 : json.tcExtMoy) + " °C"));
				$("#consoPellet").text(DecSepa(((json.consoPellet === null) ? 0.0 : json.consoPellet) + " Kg"));
				$("#consoEcsPellet").text(DecSepa(((json.consoEcsPellet === null) ? 0.0 : json.consoEcsPellet) + " Kg"));
				$("#dju").text(DecSepa(((json.dju === null) ? 0 : json.dju) + ""));
				$("#djmoy").text(DecSepa(((json.djmoy === null) ? 0 : json.djmoy) + ""));
				$("#dje").text(DecSepa(((json.dje === null) ? 0 : json.dje) + ""));
				$("#cycle").text(DecSepa(json.nbCycle + ""));


			})
			.error(function() {
				$.growlErreur(lang.error.getIndicByMonth);
			});


	}

        function status_silo()
        {
            /*
             * Gestion des indicateurs du mois 
             */
            $.api('GET', 'rendu.getStockStatus', {}).done(function(json) {

                        // if (json.no_silo){ //if no silo, it's bag
                        // 	$("#si
