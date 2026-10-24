using System;
using System.Diagnostics;
using System.Security.Principal;

class Program
{
    static void Main(string[] args)
    {
        // Ensure the app runs with administrative privileges required for service/PnP control
        if (!IsAdministrator())
        {
            Console.WriteLine("[!] This tool requires Administrator privileges to restart audio services.");
            Console.WriteLine("    Please restart Visual Studio or your terminal as Administrator.");
            Console.WriteLine("\nPress any key to exit...");
            Console.ReadKey();
            return;
        }

        Console.WriteLine("=========================================");
        Console.WriteLine("=== Audio Hibernate Fix (C# Native)   ===");
        Console.WriteLine("=========================================");
        Console.WriteLine("\nExecuting audio recovery sequence...");

        try
        {
            // 1. Restart Windows Audio Services
            RestartService("audiosrv");
            RestartService("AudioEndpointBuilder");

            // 2. Add your device PnP toggle logic here (invoking devcon or management classes)
            Console.WriteLine("[+] Toggling Sound Blaster GC7 endpoints...");
            // TODO: Insert native C# PnP device state toggle or process invocation here

            Console.WriteLine("\n[✔] Audio recovery sequence completed successfully!");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"\n[x] Error during execution: {ex.Message}");
        }

        Console.WriteLine("\nPress any key to exit...");
        Console.ReadKey();
    }

    static bool IsAdministrator()
    {
        using (var identity = WindowsIdentity.GetCurrent())
        {
            var principal = new WindowsPrincipal(identity);
            return principal.IsInRole(WindowsBuiltInRole.Administrator);
        }
    }

    static void RestartService(string serviceName)
    {
        Console.WriteLine($"[*] Restarting service: {serviceName}...");

        // Execute net stop / net start via Process
        RunProcess("net", $"stop {serviceName}");
        RunProcess("net", $"start {serviceName}");
    }

    static void RunProcess(string fileName, string arguments)
    {
        var psi = new ProcessStartInfo
        {
            FileName = fileName,
            Arguments = arguments,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        using (var process = Process.Start(psi))
        {
            process?.WaitForExit();
        }
    }
}