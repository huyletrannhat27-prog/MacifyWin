using System;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Windows.Forms;

namespace MacifyWin
{
    internal static class Native
    {
        public const int WS_EX_LAYERED = 0x80000;
        public const int WS_EX_TOOLWINDOW = 0x80;
        public const int WS_EX_TOPMOST = 0x8;
        public const int WS_EX_NOACTIVATE = 0x08000000;

        public const int GWL_STYLE = -16;
        public const int WS_CAPTION = 0x00C00000;

        public const int WM_SYSCOMMAND = 0x0112;
        public const int SC_MINIMIZE = 0xF020;
        public const int SC_MAXIMIZE = 0xF030;
        public const int SC_CLOSE = 0xF060;
        public const int SC_RESTORE = 0xF120;
        public const int DWMWA_EXTENDED_FRAME_BOUNDS = 9;
        public const uint SWP_NOZORDER = 0x0004;
        public const uint SWP_NOACTIVATE = 0x0010;

        [StructLayout(LayoutKind.Sequential)]
        public struct RECT { public int Left, Top, Right, Bottom; }

        [StructLayout(LayoutKind.Sequential)]
        public struct POINT { public int x, y; }

        [StructLayout(LayoutKind.Sequential)]
        public struct SIZE { public int cx, cy; }

        [StructLayout(LayoutKind.Sequential, Pack = 1)]
        public struct BLENDFUNCTION
        {
            public byte BlendOp;
            public byte BlendFlags;
            public byte SourceConstantAlpha;
            public byte AlphaFormat;
        }

        [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern bool IsZoomed(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr hWnd, int nIndex);
        [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
        [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
        [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
        [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);
        [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);
        [DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr hwnd, int dwAttribute, out RECT pvAttribute, int cbAttribute);
        [DllImport("user32.dll", SetLastError = true)] public static extern bool UpdateLayeredWindow(IntPtr hwnd, IntPtr hdcDst, ref POINT pptDst, ref SIZE psize, IntPtr hdcSrc, ref POINT pprSrc, int crKey, ref BLENDFUNCTION pblend, int dwFlags);
        [DllImport("user32.dll", SetLastError = true)] public static extern IntPtr GetDC(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);
        [DllImport("gdi32.dll", SetLastError = true)] public static extern IntPtr CreateCompatibleDC(IntPtr hDC);
        [DllImport("gdi32.dll", SetLastError = true)] public static extern bool DeleteDC(IntPtr hdc);
        [DllImport("gdi32.dll")] public static extern IntPtr SelectObject(IntPtr hDC, IntPtr hObject);
        [DllImport("gdi32.dll", SetLastError = true)] public static extern bool DeleteObject(IntPtr hObject);
        [DllImport("gdi32.dll")] public static extern uint GetPixel(IntPtr hdc, int nXPos, int nYPos);

        public static void ApplyBitmap(Form form, Bitmap bmp)
        {
            IntPtr screenDc = GetDC(IntPtr.Zero);
            IntPtr memDc = CreateCompatibleDC(screenDc);
            IntPtr hBitmap = bmp.GetHbitmap(Color.FromArgb(0));
            IntPtr oldBitmap = SelectObject(memDc, hBitmap);

            SIZE size = new SIZE { cx = bmp.Width, cy = bmp.Height };
            POINT pointSource = new POINT { x = 0, y = 0 };
            POINT topPos = new POINT { x = form.Left, y = form.Top };
            BLENDFUNCTION blend = new BLENDFUNCTION
            {
                BlendOp = 0,
                BlendFlags = 0,
                SourceConstantAlpha = 255,
                AlphaFormat = 1
            };

            UpdateLayeredWindow(form.Handle, screenDc, ref topPos, ref size, memDc, ref pointSource, 0, ref blend, 2);

            SelectObject(memDc, oldBitmap);
            DeleteObject(hBitmap);
            DeleteDC(memDc);
            ReleaseDC(IntPtr.Zero, screenDc);
        }

        public static Color SampleScreenColor(int x, int y)
        {
            IntPtr dc = GetDC(IntPtr.Zero);
            uint pixel = GetPixel(dc, x, y);
            ReleaseDC(IntPtr.Zero, dc);
            if (pixel == 0xFFFFFFFF) return Color.FromArgb(255, 32, 32, 36);
            int r = (int)(pixel & 0x000000FF);
            int g = (int)((pixel & 0x0000FF00) >> 8);
            int b = (int)((pixel & 0x00FF0000) >> 16);
            return Color.FromArgb(255, r, g, b);
        }
    }

    public class RightMaskForm : Form
    {
        private const int MASK_W = 138;
        private const int MASK_H = 30;
        private Color _lastColor = Color.Empty;

        public RightMaskForm()
        {
            FormBorderStyle = FormBorderStyle.None;
            ShowInTaskbar = false;
            TopMost = true;
            Size = new Size(MASK_W, MASK_H);
            StartPosition = FormStartPosition.Manual;
        }

        protected override CreateParams CreateParams
        {
            get
            {
                CreateParams cp = base.CreateParams;
                cp.ExStyle |= Native.WS_EX_LAYERED | Native.WS_EX_TOOLWINDOW | Native.WS_EX_TOPMOST | Native.WS_EX_NOACTIVATE;
                return cp;
            }
        }

        protected override bool ShowWithoutActivation { get { return true; } }

        public void SyncToWindow(Native.RECT r)
        {
            int targetX = r.Right - MASK_W - 1;
            int targetY = r.Top + 1;
            if (targetX <= r.Left + 90)
            {
                if (this.Visible) this.Hide();
                return;
            }

            // Lay mau nen thanh tieu de ngay ben trai cum nut Windows de che khop mau tu nhien
            Color sampled = Native.SampleScreenColor(targetX - 6, targetY + 12);
            bool moved = (this.Left != targetX || this.Top != targetY);
            if (moved) this.Location = new Point(targetX, targetY);
            if (!this.Visible) this.Show();

            if (moved || sampled.ToArgb() != _lastColor.ToArgb())
            {
                _lastColor = sampled;
                using (Bitmap bmp = new Bitmap(MASK_W, MASK_H, PixelFormat.Format32bppArgb))
                using (Graphics g = Graphics.FromImage(bmp))
                using (GraphicsPath path = new GraphicsPath())
                using (SolidBrush br = new SolidBrush(sampled))
                {
                    g.SmoothingMode = SmoothingMode.AntiAlias;
                    g.Clear(Color.Transparent);
                    int rad = 8;
                    path.AddLine(0, 0, MASK_W - rad, 0);
                    path.AddArc(MASK_W - rad, 0, rad, rad, 270, 90);
                    path.AddLine(MASK_W, rad, MASK_W, MASK_H);
                    path.AddLine(MASK_W, MASK_H, 0, MASK_H);
                    path.CloseFigure();
                    g.FillPath(br, path);
                    Native.ApplyBitmap(this, bmp);
                }
            }
        }
    }

    public class MacTrafficLightsForm : Form
    {
        private const int W = 68;
        private const int H = 24;
        private const int D = 12;
        private const int GAP = 8;
        private const int PAD_X = 8;
        private const int PAD_Y = 6;

        private System.Windows.Forms.Timer _timer;
        private System.Windows.Forms.Timer _greenHoverTimer;
        private NotifyIcon _tray;
        private ContextMenuStrip _greenMenu;
        private RightMaskForm _rightMask;
        private MenuItem _hideRightMenuItem;
        private bool _hideRightButtons = true;
        private IntPtr _targetHwnd = IntPtr.Zero;
        private int _hoverIndex = -1;
        private bool _isHovered = false;
        private uint _selfPid;

        public MacTrafficLightsForm()
        {
            _selfPid = (uint)Process.GetCurrentProcess().Id;
            FormBorderStyle = FormBorderStyle.None;
            ShowInTaskbar = false;
            TopMost = true;
            Size = new Size(W, H);
            StartPosition = FormStartPosition.Manual;

            _rightMask = new RightMaskForm();

            _hideRightMenuItem = new MenuItem("Hide Right Windows Buttons");
            _hideRightMenuItem.Checked = _hideRightButtons;
            _hideRightMenuItem.Click += delegate
            {
                _hideRightButtons = !_hideRightButtons;
                _hideRightMenuItem.Checked = _hideRightButtons;
                if (!_hideRightButtons && _rightMask.Visible) _rightMask.Hide();
            };

            ContextMenu menu = new ContextMenu();
            menu.MenuItems.Add("MacifyWin Traffic Lights").Enabled = false;
            menu.MenuItems.Add(_hideRightMenuItem);
            menu.MenuItems.Add("-");
            menu.MenuItems.Add("Exit", delegate { Application.Exit(); });

            _tray = new NotifyIcon();
            _tray.Icon = SystemIcons.Application;
            _tray.Text = "MacifyWin Traffic Lights";
            _tray.ContextMenu = menu;
            _tray.Visible = true;

            _greenMenu = new ContextMenuStrip();
            _greenMenu.Items.Add("Maximize / Restore", null, delegate { ToggleMaximize(); });
            _greenMenu.Items.Add("Tile Window to Left of Screen", null, delegate { TileTarget(true); });
            _greenMenu.Items.Add("Tile Window to Right of Screen", null, delegate { TileTarget(false); });

            _greenHoverTimer = new System.Windows.Forms.Timer();
            _greenHoverTimer.Interval = 450;
            _greenHoverTimer.Tick += delegate
            {
                _greenHoverTimer.Stop();
                if (_hoverIndex == 2 && _targetHwnd != IntPtr.Zero)
                {
                    _greenMenu.Show(this, new Point(PAD_X + 2 * (D + GAP), H + 2));
                }
            };

            _timer = new System.Windows.Forms.Timer();
            _timer.Interval = 33;
            _timer.Tick += OnTick;
            _timer.Start();
        }

        private void ToggleMaximize()
        {
            if (_targetHwnd == IntPtr.Zero) return;
            int cmd = Native.IsZoomed(_targetHwnd) ? Native.SC_RESTORE : Native.SC_MAXIMIZE;
            Native.PostMessage(_targetHwnd, Native.WM_SYSCOMMAND, (IntPtr)cmd, IntPtr.Zero);
        }

        private void TileTarget(bool leftHalf)
        {
            if (_targetHwnd == IntPtr.Zero) return;
            if (Native.IsZoomed(_targetHwnd)) Native.ShowWindow(_targetHwnd, 9);
            Screen scr = Screen.FromHandle(_targetHwnd);
            Rectangle wa = scr.WorkingArea;
            int halfW = wa.Width / 2;
            int x = leftHalf ? wa.Left : wa.Left + halfW;
            Native.SetWindowPos(_targetHwnd, IntPtr.Zero, x, wa.Top, halfW, wa.Height, Native.SWP_NOZORDER | Native.SWP_NOACTIVATE);
        }

        protected override CreateParams CreateParams
        {
            get
            {
                CreateParams cp = base.CreateParams;
                cp.ExStyle |= Native.WS_EX_LAYERED | Native.WS_EX_TOOLWINDOW | Native.WS_EX_TOPMOST | Native.WS_EX_NOACTIVATE;
                return cp;
            }
        }

        protected override bool ShowWithoutActivation { get { return true; } }

        private bool ShouldIgnoreWindow(IntPtr hwnd)
        {
            if (hwnd == IntPtr.Zero || hwnd == this.Handle || (_rightMask != null && hwnd == _rightMask.Handle)) return true;
            if (!Native.IsWindowVisible(hwnd) || Native.IsIconic(hwnd)) return true;

            uint pid;
            Native.GetWindowThreadProcessId(hwnd, out pid);
            if (pid == _selfPid) return true;

            StringBuilder sb = new StringBuilder(256);
            Native.GetClassName(hwnd, sb, sb.Capacity);
            string cls = sb.ToString();
            if (cls == "Shell_TrayWnd" || cls == "Shell_SecondaryTrayWnd" || cls == "Progman" ||
                cls == "WorkerW" || cls == "Windows.UI.Core.CoreWindow" || cls == "ForegroundStaging" ||
                cls == "MultitaskingViewFrame" || cls == "TaskListThumbnailWnd")
            {
                return true;
            }

            try
            {
                Process p = Process.GetProcessById((int)pid);
                string pname = p.ProcessName.ToLowerInvariant();
                if (pname.Contains("seelen") || pname == "searchhost" || pname == "startmenuexperiencehost" ||
                    pname == "shellexperiencehost" || pname == "lockapp")
                {
                    return true;
                }
            }
            catch { }

            return false;
        }

        private Native.RECT GetVisibleRect(IntPtr hwnd)
        {
            Native.RECT r;
            if (Native.DwmGetWindowAttribute(hwnd, Native.DWMWA_EXTENDED_FRAME_BOUNDS, out r, Marshal.SizeOf(typeof(Native.RECT))) != 0)
            {
                Native.GetWindowRect(hwnd, out r);
            }
            return r;
        }

        private void HideOverlays()
        {
            if (this.Visible) this.Hide();
            if (_rightMask != null && _rightMask.Visible) _rightMask.Hide();
        }

        private void OnTick(object sender, EventArgs e)
        {
            if (_greenMenu != null && _greenMenu.Visible) return;

            IntPtr fg = Native.GetForegroundWindow();
            if (ShouldIgnoreWindow(fg))
            {
                HideOverlays();
                _targetHwnd = IntPtr.Zero;
                return;
            }

            Native.RECT r = GetVisibleRect(fg);
            int width = r.Right - r.Left;
            int height = r.Bottom - r.Top;
            if (width < 260 || height < 120)
            {
                HideOverlays();
                return;
            }

            // Chi an voi app fullscreen borderless (game/video) khong co WS_CAPTION
            Screen scr = Screen.FromPoint(new Point(r.Left + 20, r.Top + 20));
            int style = Native.GetWindowLong(fg, Native.GWL_STYLE);
            if (width >= scr.Bounds.Width && height >= scr.Bounds.Height && (style & Native.WS_CAPTION) == 0)
            {
                HideOverlays();
                return;
            }

            _targetHwnd = fg;
            int targetX = r.Left + 10;
            int targetY = r.Top + 6;
            if (this.Location.X != targetX || this.Location.Y != targetY)
            {
                this.Location = new Point(targetX, targetY);
            }
            if (!this.Visible) this.Show();
            RenderLayered();

            if (_hideRightButtons && _rightMask != null)
            {
                _rightMask.SyncToWindow(r);
            }
        }

        protected override void OnMouseMove(MouseEventArgs e)
        {
            base.OnMouseMove(e);
            _isHovered = true;
            int newHover = -1;
            for (int i = 0; i < 3; i++)
            {
                int cx = PAD_X + i * (D + GAP) + D / 2;
                int cy = PAD_Y + D / 2;
                int dx = e.X - cx;
                int dy = e.Y - cy;
                if (dx * dx + dy * dy <= (D / 2 + 2) * (D / 2 + 2))
                {
                    newHover = i;
                    break;
                }
            }
            if (newHover != _hoverIndex)
            {
                _hoverIndex = newHover;
                if (_hoverIndex == 2)
                    _greenHoverTimer.Start();
                else
                    _greenHoverTimer.Stop();
                RenderLayered();
            }
        }

        protected override void OnMouseLeave(EventArgs e)
        {
            base.OnMouseLeave(e);
            _isHovered = false;
            _hoverIndex = -1;
            _greenHoverTimer.Stop();
            RenderLayered();
        }

        protected override void OnMouseClick(MouseEventArgs e)
        {
            base.OnMouseClick(e);
            if (_targetHwnd == IntPtr.Zero) return;

            if (e.Button == MouseButtons.Right && _hoverIndex == 2)
            {
                _greenHoverTimer.Stop();
                _greenMenu.Show(this, new Point(PAD_X + 2 * (D + GAP), H + 2));
                return;
            }

            if (e.Button != MouseButtons.Left) return;
            _greenHoverTimer.Stop();

            if (_hoverIndex == 0)
            {
                Native.PostMessage(_targetHwnd, Native.WM_SYSCOMMAND, (IntPtr)Native.SC_CLOSE, IntPtr.Zero);
            }
            else if (_hoverIndex == 1)
            {
                Native.PostMessage(_targetHwnd, Native.WM_SYSCOMMAND, (IntPtr)Native.SC_MINIMIZE, IntPtr.Zero);
            }
            else if (_hoverIndex == 2)
            {
                ToggleMaximize();
            }
        }

        private void RenderLayered()
        {
            using (Bitmap bmp = new Bitmap(W, H, PixelFormat.Format32bppArgb))
            using (Graphics g = Graphics.FromImage(bmp))
            {
                g.SmoothingMode = SmoothingMode.AntiAlias;
                g.Clear(Color.Transparent);

                using (GraphicsPath pill = RoundedRect(new Rectangle(0, 0, W - 1, H - 1), H / 2))
                using (SolidBrush bg = new SolidBrush(Color.FromArgb(165, 28, 28, 32)))
                using (Pen border = new Pen(Color.FromArgb(55, 255, 255, 255), 1f))
                {
                    g.FillPath(bg, pill);
                    g.DrawPath(border, pill);
                }

                Color[] colors = new Color[]
                {
                    Color.FromArgb(255, 255, 95, 86),
                    Color.FromArgb(255, 255, 189, 46),
                    Color.FromArgb(255, 39, 201, 63)
                };

                for (int i = 0; i < 3; i++)
                {
                    int x = PAD_X + i * (D + GAP);
                    int y = PAD_Y;
                    using (SolidBrush b = new SolidBrush(colors[i]))
                    {
                        g.FillEllipse(b, x, y, D, D);
                    }
                    if (_isHovered)
                    {
                        using (Pen p = new Pen(Color.FromArgb(200, 45, 20, 10), 1.4f))
                        {
                            if (i == 0)
                            {
                                g.DrawLine(p, x + 3.5f, y + 3.5f, x + D - 3.5f, y + D - 3.5f);
                                g.DrawLine(p, x + D - 3.5f, y + 3.5f, x + 3.5f, y + D - 3.5f);
                            }
                            else if (i == 1)
                            {
                                g.DrawLine(p, x + 3f, y + D / 2f, x + D - 3f, y + D / 2f);
                            }
                            else if (i == 2)
                            {
                                g.DrawLine(p, x + 3f, y + D / 2f, x + D - 3f, y + D / 2f);
                                g.DrawLine(p, x + D / 2f, y + 3f, x + D / 2f, y + D - 3f);
                            }
                        }
                    }
                }

                Native.ApplyBitmap(this, bmp);
            }
        }

        private GraphicsPath RoundedRect(Rectangle bounds, int radius)
        {
            int d = radius * 2;
            GraphicsPath path = new GraphicsPath();
            path.AddArc(bounds.X, bounds.Y, d, d, 180, 90);
            path.AddArc(bounds.Right - d, bounds.Y, d, d, 270, 90);
            path.AddArc(bounds.Right - d, bounds.Bottom - d, d, d, 0, 90);
            path.AddArc(bounds.X, bounds.Bottom - d, d, d, 90, 90);
            path.CloseFigure();
            return path;
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                if (_timer != null) _timer.Dispose();
                if (_greenHoverTimer != null) _greenHoverTimer.Dispose();
                if (_greenMenu != null) _greenMenu.Dispose();
                if (_rightMask != null) _rightMask.Dispose();
                if (_tray != null) _tray.Dispose();
            }
            base.Dispose(disposing);
        }

        [STAThread]
        public static void Main()
        {
            bool createdNew;
            using (Mutex m = new Mutex(true, "MacifyWin_MacTrafficLights_Mutex", out createdNew))
            {
                if (!createdNew) return;
                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                Application.Run(new MacTrafficLightsForm());
            }
        }
    }
}
