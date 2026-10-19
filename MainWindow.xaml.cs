using System;
using System.Diagnostics;
using System.Windows;

namespace AudioHibernateFix
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
        }

        private async void FixButton_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                FixButton.IsEnabled = false; // Prevent double-clicks / looping triggers
                StatusText.Text = "Stopping audio services...";

                RunProcess("net", "stop audiosrv /y");
                await System.Threading.Tasks.Task.Delay(1000); // Give Windows a second to breathe

                StatusText.Text = "Stopping endpoint builder...";
                RunProcess("net", "stop AudioEndpointBuilder /y");
                await System.Threading.Tasks.Task.Delay(1000);

                StatusText.Text = "Restarting audio services...";
                RunProcess("net", "start AudioEndpointBuilder");
                await System.Threading.Tasks.Task.Delay(1000);

                RunProcess("net", "start audiosrv");
                await System.Threading.Tasks.Task.Delay(1000);

                // TODO: Insert your Sound Blaster GC7 USB PnP toggle here (recreating your 2.10 logic)
                StatusText.Text = "Audio Fix Completed Successfully!";
            }
            catch (Exception ex)
            {
                StatusText.Text = $"Error: {ex.Message}";
            }
            finally
            {
                FixButton.IsEnabled = true;
            }
        }

        private void RunProcess(string fileName, string arguments)
        {
            var psi = new ProcessStartInfo
            {
                FileName = fileName,
                Arguments = arguments,
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };

            using (var process = Process.Start(psi))
            {
                process?.WaitForExit();
            }
        }
    }
}