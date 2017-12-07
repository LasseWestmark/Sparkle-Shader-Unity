using System.Diagnostics;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Callbacks;
using UnityEngine;

public static class SublimeText3
{
	private const string applicationPath = @"C:\Program Files\Sublime Text 3\sublime_text.exe";
	private static readonly string projectRoot = Path.Combine(Application.dataPath, "..");

	[MenuItem("Assets/Open in Sublime Text 3")]
	private static void OpenInSublimeText3()
	{
		foreach (var o in Selection.objects)
		{
			var file = GetFilePath(AssetDatabase.GetAssetPath(o));
			Open(file, 0);
		}
	}

	[MenuItem("Assets/Open in Sublime Text 3", true)]
	private static bool CanOpenInSublimeText3()
	{
		if (Selection.objects.Length == 0)
		{
			return false;
		}

		return Selection.objects.All(o =>
		{
			if (AssetDatabase.IsMainAsset(o))
			{
				var file = GetFilePath(AssetDatabase.GetAssetPath(o));
				return File.Exists(file) && File.Exists(applicationPath);
			}

			return false;
		});
	}

	[OnOpenAsset]
	private static bool OpenShadersInSublimeText(int instanceId, int line)
	{
		var file = GetFilePath(AssetDatabase.GetAssetPath(Selection.activeObject));
		if (file.EndsWith(".shader") || file.EndsWith(".compute") || file.EndsWith(".cginc"))
		{
			return Open(file, line);
		}
		return false;
	}

	private static string GetFilePath(string assetPath)
	{
		return Path.GetFullPath(Path.Combine(projectRoot, assetPath));
	}

	private static bool Open(string file, int line)
	{
		if (!File.Exists(file) || !File.Exists(applicationPath))
		{
			return false;
		}

		Process.Start(new ProcessStartInfo
		{
			UseShellExecute = false,
			CreateNoWindow = true,
			Arguments = string.Format("\"{0}\"", file),
			FileName = string.Format("\"{0}\"", applicationPath)
			
		});
		return true;
	}
}