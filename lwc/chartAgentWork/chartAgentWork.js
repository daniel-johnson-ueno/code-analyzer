import { LightningElement, track, wire } from 'lwc';
import ChartJS from '@salesforce/resourceUrl/ChartJsV3';
import {loadScript} from 'lightning/platformResourceLoader';
import getChartData from '@salesforce/apex/ChartAgentWorkController.getChartData';
import getChannels from '@salesforce/apex/ChartAgentWorkController.getChannels';

export default class ChartAgentWork extends LightningElement {

    @track chartJsInitialized = false;
    @track chartInfo = [];
    chartInstance;
    @track startDate = new Date();
    @track initDate = this.startDate.toISOString().split('T')[0];
    @track channelOptions = [];
    @track selectedChannel = 'Telefono';
    @track selectedDate = this.initDate;

    connectedCallback(){
        this.initializeChartJS();
        this.renderChartInfo(this.startDate);
    }

    @wire(getChannels)
    wiredChannels({ error, data }) {
        if (data) {
            this.channelOptions = data.map(channel => ({
                label: channel, 
                value: channel
            }));
        } else if (error) {
            console.error('Error fetching channels:', error);
        }
    }

    initializeChartJS() {
        loadScript(this, ChartJS)
        .then(() => {
            this.chartJsInitialized = true;
        })
        .catch(error => {
            showErrorMessage('Error', error?.body?.message);
        });
    }

    renderChartInfo(searchDate) {
        getChartData({searchDate: searchDate, channel: this.selectedChannel})
        .then( response => {
            setTimeout(() => {
                if(this.chartJsInitialized){
                    this.initializeWorkItemsChart(response);
                }
            }, "2000");
        })
        .catch(error => {
            console.log('Error al obtener datos: ', error);
        });
    }

    initializeWorkItemsChart = (data) => {
        try {
            const canvas = this.template.querySelector('canvas');
            if (!canvas) {
                throw new Error('No se encontró el elemento <canvas> en el DOM.');
            }

            const ctx = canvas.getContext('2d');

            const config = {
                type: 'line',
                data: data,
                options: {
                    indexAxis: 'y',
                    responsive: false,
                    maintainAspectRatio: false,
                    interaction: {
                        mode: 'nearest',
                        intersect: false
                    },
                    scales: {
                        x: {
                            type: 'linear',
                            min: 0,
                            max: 1440,
                            grid: {
                                offset: true
                              },
                            ticks: {
                                padding: 10,
                                stepSize: 30,
                                autoSkip: true,
                                callback: this.ticksCallback,
                            },
                            title: {
                                display: true,
                                text: 'Horario'
                            }
                        },
                        y: {
                            grid: {
                                offset: true
                              },
                            ticks: {
                                padding: 10,
                                stepSize: 10,
                                autoSkip: false, //modificado
//                                callback: this.ticksCallback,
                            },
                            title: {
                                display: true,
                                text: 'Usuarios'
                            }
                        }
                    },
                    plugins: {
                        legend: {
                            position: 'bottom',
                            labels: {
                                boxWidth: 1,
                                boxHeight: 1,
                                font: {
                                    size: 11,
                                    family: 'Arial',
                                    weight: 'bold'
                                },
                                padding: 15,
                                filter: this.filterLabels
                              },
                            onClick: this.toggleLegendItems,
                        },
                        title: {
                            display: false,
                            text: 'Items de Trabajo por Usuario y Horario',
                            padding: {
                                bottom: 20
                              }
                        },
                        tooltip: {
                            mode: 'nearest',
                            intersect: false,
                            displayColors: false,
                            callbacks: {
                                label: function (tooltipItem) {
                                    const dataset = tooltipItem.dataset;
                                    const dataPoints = dataset.data;
                                    const index = tooltipItem.dataIndex;
                                    const value = dataPoints[index];
                                    const label = dataset.label;
                                    const id = dataset.recordId != null ? dataset.recordId : 'N/A';

                                    const formatMinutesToTime = (minutes) => {
                                        const hours = Math.floor(minutes / 60);
                                        const mins = minutes % 60;
                                        return `${hours.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}`;
                                    };

                                    const startTime = formatMinutesToTime(dataPoints[0].x);
                                    const endTime = formatMinutesToTime(dataPoints[dataPoints.length - 1].x);

                                    if (index === 0 || index === dataPoints.length - 1) {
                                        return `Hora Inicio: ${startTime}, Hora Fin: ${endTime}, Tarea: ${label}, ID: ${id}`;
                                    } else {
                                        return `Hora: ${formatMinutesToTime(value.x)}, Tarea: ${label}, ID: ${id}`;
                                    }
                                }
                            }
                        }
                    },
                    elements: {
                        line: {
                            tension: 0,
                            hoverBorderWidth: 10
                        },
                        point: {
                            radius: 0,
                            hitRadius: 10,
                            hoverRadius: 5,
                        }
                    }
                }
            };

            this.chartInstance = new window.Chart(ctx, config);
        } catch (error) {
            console.log('Error al inicializar el gráfico:', error);
        }
    }

    handleChangeDate(event) {
        if (event.detail.value != null) {
            this.selectedDate = event.detail.value;
            this.fetchAndRenderChartData();
        }
    }

    handleChangeChannel(event) {
        if (event.detail.value != null) {
            this.selectedChannel = event.detail.value;
            this.fetchAndRenderChartData();
        }
    }

    fetchAndRenderChartData() {
        if (this.selectedDate && this.selectedChannel) {
            const searchDate = new Date(this.selectedDate);
            getChartData({ searchDate: searchDate, channel: this.selectedChannel })
                .then(response => {
                    this.updateChartData(response);
                })
                .catch(error => {
                    console.error('Error al obtener datos del gráfico:', error);
                });
        }
    }

    updateChartData(data){
        this.chartInstance.data =  data;
        this.chartInstance.update();
    }

    ticksCallback = (minutes) => {
        const hours = Math.floor(minutes / 60);
        const mins = minutes % 60;
        return `${hours.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}`;
    }

    filterLabels = (legendItem, chartData) => {
        const isDuplicate = chartData.datasets
          .slice(0, legendItem.datasetIndex)
          .some(ds => ds.label === legendItem.text);
        return !isDuplicate;
      };

    toggleLegendItems = (e, legendItem, legend) => {
        const chart = legend.chart;
        const label = legendItem.text;
        const isVisible = chart.isDatasetVisible(legendItem.datasetIndex);
        chart.data.datasets.forEach((dataset, index) => {
            if (dataset.label === label) {
                const meta = chart.getDatasetMeta(index);
                meta.hidden = isVisible;
            }
        });
        chart.update();
    };
}